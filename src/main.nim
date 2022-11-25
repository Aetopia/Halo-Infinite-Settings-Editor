import wNim/[wApp, wFrame, wPanel, wListCtrl, wStaticLine, wButton, wMessageDialog, wTextEntryDialog]
import winim/shell
import algorithm
import json 
import os
import tables
import strutils

proc getGamePlatCfgFile: string =
    # Get "SpecControlSettings.json" based on where game was downloaded from.
    
    let localappdata = getEnv("LOCALAPPDATA")
    for f in [
        "HaloInfinite\\Settings\\SpecControlSettings.json", 
        "Packages\\Microsoft.254428597CFE2_8wekyb3d8bbwe\\LocalCache\\Local\\HaloInfinite\\Settings\\SpecControlSettings.json"
        ]:
        let path = localappdata/f
        if fileExists(path): return path
    MessageDialog(nil, "\"SpecControlSettings.json\" doesn't exist!", "Halo Infinite Settings Editor", wOk or wIconExclamation).display()
    quit(1)

proc getSettings(file: string): seq[(string, string)] = 
    # Parse "SpecControlSettings.json" into Key ~ Value pairs.

    let cfg = parseFile(file).fields
    var 
        settings: seq[(string, string)]
        v: string

    for k, n in cfg:
        case n["value"].kind:
            of JNull: v = " "
            of JInt: v = n["value"].getInt.intToStr
            else: v = n["value"].getStr()
        settings.add((k, v))
    return settings

proc loadList(list: wListCtrl, settings: seq[(string, string)]) =
    # Load Key ~ Value pairs into the ListCtrl.

    list.deleteAllItems()
    for i in reversed(settings):
        list.insertItem(0, i[0])
        list.setItem(0, 1, i[1])

proc saveSettings(list: wListCtrl, file: string) = 
    # Save the current settings into "SpecControlSettings.json".


    var cfg = parseFile(file)
    for i in 0..list.getItemCount()-1:
        let 
            n = cfg[list.getItemText(i, 0).strip()]
            v = list.getItemText(i, 1).strip()
        if v == "": n.add("value", newJNull())
        else:
            try: n.add("value", newJInt(v.parseInt))
            except ValueError: n.add("value", newJString(v))
    writeFile(file, cfg.pretty(indent=4))
            
proc searchSettings(list: wListCtrl, query: string): seq[int] = 
    # Search through Keys with the specified query.

    if query == "": return @[]

    var results: seq[int]
    let keys = 0..list.getItemCount()-1
    for i in keys:
        for j in [0, 1]:
            for j in [wListStateFocused, wListStateSelected, wListStateDropHighlighted, wListStateCut, 0x00000003]:
                list.setItemState(i, j, wListStateDropHighlighted, false)

    for i in keys:
        let v = list.getItemText(i, 0)
        if v.contains(query.strip()): 
            for j in [0, 1]:
                list.setItemState(i, j, wListStateDropHighlighted)
            results.add(i)
    return results

proc clearSearchResults(list: wListCtrl, results: seq[int]): seq[int] = 
    # Clear search results.
    
    for i in results:  
        for j in [0, 1]:
            list.setItemState(i, j, wListStateDropHighlighted, false) 
    return @[]


if isMainModule:
    # GUI and Main function of the program.

    let 
        app = App()
        frame = Frame(title="Halo Infinite Settings Editor", style=wSystemMenu or wMinimizeBox or wCaption, size=(800, 600))
        panel = frame.Panel()
        save = panel.Button(label="✍️ Save", size=(60, 23))
        reload = panel.Button(label="↻ Reload", pos=(60, 0), size=(60, 23))
        search = panel.Button(label="🔎 Search", pos=(120, 0), size=(60, 23))
        open = panel.Button(label="📄 Open", pos=(180, 0), size=(60, 23))
        repo = panel.Button(label="🌎", pos=(748, 0), size=(23, 23))
        about = panel.Button(label="?", pos=(771, 0), size=(23, 23))
        list = panel.ListCtrl(style=wLcReport or wLcNoHeader or wLcSingleSel, size=(795, 547), pos=(0, 23))
        file = getGamePlatCfgFile()
    var 
        results: seq[int]
        selected: int

    list.setExtendedStyle(LVS_EX_GRIDLINES or LVS_EX_BORDERSELECT)
    list.insertColumn(0)
    list.setColumnWidth(0, 400)
    list.insertColumn(1)
    list.setColumnWidth(1, 375)

    list.wEvent_ListItemActivated do (event: wEvent): 
        results = clearSearchResults(list, results)
        let 
            i = event.getIndex()
            dialog = list.TextEntryDialog(caption="✎ Edit", message=list.getItemText(i, 0), value=list.getItemText(i, 1).strip())
        var v: string

        if dialog.showModal() == wIdOk: 
            v = dialog.getValue().strip()
            if v == "": v = " "
            list.setItem(i, 1, v)

    list.wEvent_ListItemSelected do (event: wEvent): 
        if results != @[]:
            results = clearSearchResults(list, results)
        selected = event.getIndex()
            

    save.wEvent_Button do ():
        if results != @[]:
            results = clearSearchResults(list, results)
        saveSettings(list, file)
        frame.MessageDialog("Settings saved!", "✍️ Save", wOk or wIconInformation).display()
        list.setFocus()

    reload.wEvent_Button do ():
        if results != @[]:
            results = clearSearchResults(list, results)
        loadList(list, getSettings(file))
        list.setFocus()

    search.wEvent_Button do ():
        results = searchSettings(list, search.TextEntryDialog(caption="🔎 Search", message="").display())
        if results != @[]:
            for i in [0, 1]:
                list.setItemState(selected, i, 0x00000003, false)
        list.setFocus()

    open.wEvent_Button do ():
        if results != @[]:    
            results = clearSearchResults(list, results)
        ShellExecute(0, "open", file, nil, nil, 0)
        list.setFocus()
    
    repo.wEvent_Button do ():
        if results != @[]:
            results = clearSearchResults(list, results)
        ShellExecute(0, "open", "https://github.com/Aetopia/Halo-Infinite-Settings-Editor", nil, nil, 0)
        list.setFocus()
        
    about.wEvent_Button do ():
        if results != @[]:
            results = clearSearchResults(list, results)
        panel.MessageDialog("Created by Aetopia\nhttps://github.com/Aetopia/Halo-Infinite-Settings-Editor", "About", wOk or wIconInformation).display
        list.setFocus()

    reload.click()
    panel.Button(size=(-1, -1), pos=(-1, -1)).setFocus()
    frame.center()
    frame.show()
    app.run()