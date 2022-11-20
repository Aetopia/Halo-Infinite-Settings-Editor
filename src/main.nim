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
            
        
if isMainModule:
    let 
        app = App()
        frame = Frame(title="Halo Infinite Settings Editor", style=wSystemMenu, size=(800, 600))
        panel = frame.Panel()
        save = panel.Button(label="✎ Save", size=(60, 23))
        reload = panel.Button(label="↻ Reload", pos=(59, 0), size=(60, 23))
        open = panel.Button(label="📄 Open", pos=(118, 0), size=(60, 23))
        about = panel.Button(label="?", pos=(771, 0), size=(23, 23))
        list = panel.ListCtrl(style=wLcReport or wLcNoHeader or wLcSingleSel, size=(795, 547), pos=(0, 24))
        file = getGamePlatCfgFile()

    panel.StaticLine(pos=(0, 23), size=(795, -1))
    list.insertColumn(0)
    list.setColumnWidth(0, 370)
    list.insertColumn(1)
    list.setColumnWidth(1, 369)

    list.wEvent_ListItemActivated do (event: wEvent): 
        let 
            i = event.getIndex()
            dialog = list.TextEntryDialog(caption="Edit", message=list.getItemText(i, 0), value=list.getItemText(i, 1).strip())
        var v: string

        if dialog.showModal() == wIdOk: 
            v = dialog.getValue().strip()
            if v == "": v = " "
            list.setItem(i, 1, v)

    save.wEvent_Button do ():
        saveSettings(list, file)
        frame.MessageDialog("Settings saved!", "Halo Infinite Settings Editor", wOk or wIconInformation).display
    reload.wEvent_Button do ():
        loadList(list, getSettings(file))
    open.wEvent_Button do ():
        ShellExecuteW(0, "open", file, nil, nil, 0)
    about.wEvent_Button do ():
        panel.MessageDialog("Created by Aetopia\nhttps://github.com/Aetopia/Halo-Infinite-Settings-Editor", "About", wOk or wIconInformation).display

    reload.click()
    panel.Button(size=(-1, -1), pos=(-1, -1)).setFocus()
    frame.center()
    frame.show()
    app.run()