import wNim/[wApp, wFrame, wPanel, wListCtrl, wStaticLine, wButton, wMessageDialog, wTextEntryDialog]
import winim/shell
import algorithm
import json 
import os
import tables
import strutils

proc getGamePlatCfgFile: string =
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
    list.deleteAllItems()
    for i in reversed(settings):
        list.insertItem(0, i[0])
        list.setItem(0, 1, i[1])

proc saveSettings(list: wListCtrl, file: string) = 
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
            
proc searchSettings(list: wListCtrl, query: string) = 
    if query == "": return
    list.scrollList(-1, -1)
    for i in 0..list.getItemCount()-1:
        let v = list.getItemText(i, 0)
        if v.contains(query.strip()): 
            list.setItemState(i, 0, wListStateDropHighlighted)

proc defaultListView(list: wListCtrl) = 
    for i in 0..list.getItemCount()-1:  
        list.setItemState(i, 0, wListStateDropHighlighted, false) 


if isMainModule:
    let 
        app = App()
        frame = Frame(title="Halo Infinite Settings Editor", style=wSystemMenu or wModalFrame, size=(800, 600))
        panel = frame.Panel()
        save = panel.Button(label="✍️", size=(23, 23))
        reload = panel.Button(label="↻", pos=(23, 0), size=(23, 23))
        search = panel.Button(label="🔎", pos=(46, 0), size=(23, 23))
        open = panel.Button(label="📄", pos=(69, 0), size=(23, 23))
        about = panel.Button(label="?", pos=(92, 0), size=(23, 23))
        list = panel.ListCtrl(style=wLcReport or wLcNoHeader or wLcSingleSel, size=(795, 547), pos=(0, 23))
        file = getGamePlatCfgFile()

    list.setExtendedStyle(LVS_EX_UNDERLINEHOT or LVS_EX_GRIDLINES or LVS_EX_BORDERSELECT)
    list.insertColumn(0)
    list.setColumnWidth(0, 400)
    list.insertColumn(1)
    list.setColumnWidth(1, 375)

    list.wEvent_ListItemActivated do (event: wEvent): 
        defaultListView(list)
        let 
            i = event.getIndex()
            dialog = list.TextEntryDialog(caption="✎ Edit", message=list.getItemText(i, 0), value=list.getItemText(i, 1).strip())
        var v: string

        if dialog.showModal() == wIdOk: 
            v = dialog.getValue().strip()
            if v == "": v = " "
            list.setItem(i, 1, v)

    save.wEvent_Button do ():
        defaultListView(list)
        saveSettings(list, file)
        frame.MessageDialog("Settings saved!", "✍️ Save", wOk or wIconInformation).display()
        list.setFocus()

    reload.wEvent_Button do ():
        defaultListView(list)
        loadList(list, getSettings(file))
        list.setFocus()

    search.wEvent_Button do ():
        defaultListView(list)
        searchSettings(list, search.TextEntryDialog(caption="🔎 Search", message="").display())
        list.setFocus()

    open.wEvent_Button do ():
        defaultListView(list)
        ShellExecuteW(0, "open", file, nil, nil, 0)
        list.setFocus()

    about.wEvent_Button do ():
        defaultListView(list)
        panel.MessageDialog("Created by Aetopia\nhttps://github.com/Aetopia/Halo-Infinite-Settings-Editor", "About", wOk or wIconInformation).display
        list.setFocus()

    reload.click()
    panel.Button(size=(-1, -1), pos=(-1, -1)).setFocus()
    frame.center()
    frame.show()
    app.run()