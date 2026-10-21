{
 "patcher": {
  "fileversion": 1,
  "appversion": {
   "major": 9,
   "minor": 0,
   "revision": 7,
   "architecture": "x64",
   "modernui": 1
  },
  "classnamespace": "box",
  "rect": [
   100,
   100,
   760,
   480
  ],
  "openinpresentation": 1,
  "default_fontsize": 10.0,
  "default_fontface": 0,
  "default_fontname": "Arial Bold",
  "gridonopen": 1,
  "gridsize": [
   8,
   8
  ],
  "gridsnaponopen": 1,
  "toolbarvisible": 1,
  "boxanimatetime": 200,
  "enablehscroll": 1,
  "enablevscroll": 1,
  "devicewidth": 396.0,
  "description": "Detects BPM and song sections, adds section clips and guide cues.",
  "digest": "",
  "tags": "",
  "style": "",
  "subpatcher_template": "",
  "boxes": [
   {
    "box": {
     "id": "obj-in",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 2,
     "patching_rect": [
      20,
      20,
      70,
      22
     ],
     "outlettype": [
      "signal",
      "signal"
     ],
     "text": "plugin~ 2"
    }
   },
   {
    "box": {
     "id": "obj-out",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 0,
     "patching_rect": [
      20,
      420,
      70,
      22
     ],
     "text": "plugout~ 2"
    }
   },
   {
    "box": {
     "id": "obj-title",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      120,
      20,
      200,
      20
     ],
     "text": "SEQUENCER ANALYZER",
     "presentation": 1,
     "presentation_rect": [
      8,
      4,
      220,
      18
     ],
     "fontface": 1,
     "fontsize": 12.0
    }
   },
   {
    "box": {
     "id": "obj-cuebtn",
     "maxclass": "live.text",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      120,
      60,
      120,
      18
     ],
     "outlettype": [
      "",
      ""
     ],
     "text": "Choose Cue Folder",
     "presentation": 1,
     "presentation_rect": [
      8,
      26,
      128,
      20
     ],
     "mode": 0,
     "texton": "Choose Cue Folder",
     "varname": "CueFolder",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "CueFolder",
       "parameter_shortname": "CueFolder",
       "parameter_type": 2,
       "parameter_mmax": 1,
       "parameter_enum": [
        "val1",
        "val2"
       ],
       "parameter_invisible": 1
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-buildbtn",
     "maxclass": "live.text",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      300,
      60,
      120,
      18
     ],
     "outlettype": [
      "",
      ""
     ],
     "text": "Analyze & Build",
     "presentation": 1,
     "presentation_rect": [
      142,
      26,
      128,
      20
     ],
     "mode": 0,
     "texton": "Analyze & Build",
     "varname": "Build",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Build",
       "parameter_shortname": "Build",
       "parameter_type": 2,
       "parameter_mmax": 1,
       "parameter_enum": [
        "val1",
        "val2"
       ],
       "parameter_invisible": 1
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-tempobtn",
     "maxclass": "live.text",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      460,
      60,
      120,
      18
     ],
     "outlettype": [
      "",
      ""
     ],
     "text": "Write Tempo",
     "presentation": 1,
     "presentation_rect": [
      276,
      26,
      110,
      20
     ],
     "mode": 0,
     "texton": "Write Tempo",
     "varname": "Tempo",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Tempo",
       "parameter_shortname": "Tempo",
       "parameter_type": 2,
       "parameter_mmax": 1,
       "parameter_enum": [
        "val1",
        "val2"
       ],
       "parameter_invisible": 1
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-dialog",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      120,
      120,
      100,
      22
     ],
     "outlettype": [
      "",
      ""
     ],
     "text": "opendialog fold"
    }
   },
   {
    "box": {
     "id": "obj-prep",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      120,
      150,
      120,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend setcuedir"
    }
   },
   {
    "box": {
     "id": "obj-buildmsg",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "patching_rect": [
      300,
      120,
      50,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "build"
    }
   },
   {
    "box": {
     "id": "obj-tempomsg",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "patching_rect": [
      460,
      120,
      90,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "writetempo"
    }
   },
   {
    "box": {
     "id": "obj-node",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      120,
      220,
      260,
      22
     ],
     "outlettype": [
      "",
      ""
     ],
     "text": "node.script aicb_node.js @autostart 1 @watch 0"
    }
   },
   {
    "box": {
     "id": "obj-js",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "patching_rect": [
      300,
      280,
      120,
      22
     ],
     "outlettype": [
      "",
      "",
      ""
     ],
     "text": "js aicb_live.js"
    }
   },
   {
    "box": {
     "id": "obj-thisdev",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "patching_rect": [
      600,
      150,
      90,
      22
     ],
     "outlettype": [
      "",
      "",
      ""
     ],
     "text": "live.thisdevice"
    }
   },
   {
    "box": {
     "id": "obj-delay",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 1,
     "patching_rect": [
      600,
      180,
      70,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "delay 2000"
    }
   },
   {
    "box": {
     "id": "obj-hello",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "patching_rect": [
      600,
      210,
      50,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "hello"
    }
   },
   {
    "box": {
     "id": "obj-progress",
     "maxclass": "jsui",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      480,
      300,
      200,
      8
     ],
     "outlettype": [
      ""
     ],
     "presentation": 1,
     "presentation_rect": [
      8,
      54,
      378,
      8
     ],
     "filename": "aicb_progress.js",
     "parameter_enable": 0,
     "ignoreclick": 1
    }
   },
   {
    "box": {
     "id": "obj-status",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      300,
      340,
      380,
      40
     ],
     "text": "Ready.",
     "presentation": 1,
     "presentation_rect": [
      8,
      64,
      378,
      46
     ],
     "linecount": 3,
     "fontsize": 10.5
    }
   }
  ],
  "lines": [
   {
    "patchline": {
     "source": [
      "obj-in",
      0
     ],
     "destination": [
      "obj-out",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-in",
      1
     ],
     "destination": [
      "obj-out",
      1
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-cuebtn",
      0
     ],
     "destination": [
      "obj-dialog",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-dialog",
      0
     ],
     "destination": [
      "obj-prep",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-buildbtn",
      0
     ],
     "destination": [
      "obj-buildmsg",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-tempobtn",
      0
     ],
     "destination": [
      "obj-tempomsg",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-prep",
      0
     ],
     "destination": [
      "obj-node",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-buildmsg",
      0
     ],
     "destination": [
      "obj-js",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-tempomsg",
      0
     ],
     "destination": [
      "obj-js",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-js",
      0
     ],
     "destination": [
      "obj-node",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-node",
      0
     ],
     "destination": [
      "obj-js",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-thisdev",
      0
     ],
     "destination": [
      "obj-delay",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-delay",
      0
     ],
     "destination": [
      "obj-hello",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-hello",
      0
     ],
     "destination": [
      "obj-node",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-js",
      2
     ],
     "destination": [
      "obj-progress",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-js",
      1
     ],
     "destination": [
      "obj-status",
      0
     ]
    }
   }
  ],
  "dependency_cache": [
   {
    "name": "aicb_live.js",
    "bootpath": ".",
    "type": "TEXT",
    "implicit": 1
   },
   {
    "name": "aicb_node.js",
    "bootpath": ".",
    "type": "TEXT",
    "implicit": 1
   },
   {
    "name": "aicb_progress.js",
    "bootpath": ".",
    "type": "TEXT",
    "implicit": 1
   }
  ],
  "latency": 0,
  "is_mpe": 0,
  "external_mpe_tuning_enabled": 0,
  "minimum_live_version": "",
  "minimum_max_version": "",
  "platform_compatibility": 0,
  "autosave": 0
 }
}