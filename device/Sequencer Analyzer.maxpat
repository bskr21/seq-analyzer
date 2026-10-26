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
  "default_fontsize": 10,
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
  "devicewidth": 396,
  "description": "v0.8.0-alpha.2 analysis-only panel: per-song BPM duration Arrangement bar Warp.",
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
     "text": "SEQUENCER ANALYZER | alpha.2",
     "presentation": 1,
     "presentation_rect": [
      8,
      4,
      220,
      18
     ],
     "fontface": 1,
     "fontsize": 12
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
     "text": "ANALYZE",
     "presentation": 1,
     "presentation_rect": [
      142,
      26,
      128,
      20
     ],
     "mode": 0,
     "texton": "ANALYZE",
     "varname": "Analyze",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "Analyze",
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
     "text": "BUILD (beta)",
     "presentation": 1,
     "presentation_rect": [
      276,
      26,
      110,
      20
     ],
     "mode": 0,
     "texton": "BUILD (beta)",
     "varname": "BuildBeta",
     "parameter_enable": 1,
     "activebgoncolor": [
      1,
      0.71,
      0.2,
      1
     ],
     "activetextoncolor": [
      0.1,
      0.1,
      0.1,
      1
     ],
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "BuildBeta",
       "parameter_shortname": "Follow",
       "parameter_type": 2,
       "parameter_mmax": 1,
       "parameter_enum": [
        "off",
        "on"
       ],
       "parameter_invisible": 1
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-routeslot",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 2,
     "patching_rect": [
      620,
      200,
      60,
      22
     ],
     "outlettype": [
      "",
      ""
     ],
     "text": "route slot"
    }
   },
   {
    "box": {
     "id": "obj-routeidx",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 17,
     "patching_rect": [
      620,
      230,
      300,
      22
     ],
     "outlettype": [
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      "",
      ""
     ],
     "text": "route 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15"
    }
   },
   {
    "box": {
     "id": "obj-unpack0",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "patching_rect": [
      620,
      270,
      80,
      22
     ],
     "outlettype": [
      "",
      "",
      ""
     ],
     "text": "unpack 0. 0. 0."
    }
   },
   {
    "box": {
     "id": "obj-n0start",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      620,
      300,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowStart0",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowStart0",
       "parameter_shortname": "FollowStart0",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p0start",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      620,
      400,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 0 start"
    }
   },
   {
    "box": {
     "id": "obj-n0end",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      620,
      330,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowEnd0",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowEnd0",
       "parameter_shortname": "FollowEnd0",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p0end",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      620,
      430,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 0 end"
    }
   },
   {
    "box": {
     "id": "obj-n0bpm",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      620,
      360,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowBpm0",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowBpm0",
       "parameter_shortname": "FollowBpm0",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 999,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p0bpm",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      620,
      460,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 0 bpm"
    }
   },
   {
    "box": {
     "id": "obj-unpack1",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "patching_rect": [
      740,
      270,
      80,
      22
     ],
     "outlettype": [
      "",
      "",
      ""
     ],
     "text": "unpack 0. 0. 0."
    }
   },
   {
    "box": {
     "id": "obj-n1start",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      740,
      300,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowStart1",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowStart1",
       "parameter_shortname": "FollowStart1",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p1start",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      740,
      400,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 1 start"
    }
   },
   {
    "box": {
     "id": "obj-n1end",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      740,
      330,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowEnd1",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowEnd1",
       "parameter_shortname": "FollowEnd1",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p1end",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      740,
      430,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 1 end"
    }
   },
   {
    "box": {
     "id": "obj-n1bpm",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      740,
      360,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowBpm1",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowBpm1",
       "parameter_shortname": "FollowBpm1",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 999,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p1bpm",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      740,
      460,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 1 bpm"
    }
   },
   {
    "box": {
     "id": "obj-unpack2",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "patching_rect": [
      860,
      270,
      80,
      22
     ],
     "outlettype": [
      "",
      "",
      ""
     ],
     "text": "unpack 0. 0. 0."
    }
   },
   {
    "box": {
     "id": "obj-n2start",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      860,
      300,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowStart2",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowStart2",
       "parameter_shortname": "FollowStart2",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p2start",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      860,
      400,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 2 start"
    }
   },
   {
    "box": {
     "id": "obj-n2end",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      860,
      330,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowEnd2",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowEnd2",
       "parameter_shortname": "FollowEnd2",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p2end",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      860,
      430,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 2 end"
    }
   },
   {
    "box": {
     "id": "obj-n2bpm",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      860,
      360,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowBpm2",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowBpm2",
       "parameter_shortname": "FollowBpm2",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 999,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p2bpm",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      860,
      460,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 2 bpm"
    }
   },
   {
    "box": {
     "id": "obj-unpack3",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "patching_rect": [
      980,
      270,
      80,
      22
     ],
     "outlettype": [
      "",
      "",
      ""
     ],
     "text": "unpack 0. 0. 0."
    }
   },
   {
    "box": {
     "id": "obj-n3start",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      980,
      300,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowStart3",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowStart3",
       "parameter_shortname": "FollowStart3",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p3start",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      980,
      400,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 3 start"
    }
   },
   {
    "box": {
     "id": "obj-n3end",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      980,
      330,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowEnd3",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowEnd3",
       "parameter_shortname": "FollowEnd3",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p3end",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      980,
      430,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 3 end"
    }
   },
   {
    "box": {
     "id": "obj-n3bpm",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      980,
      360,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowBpm3",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowBpm3",
       "parameter_shortname": "FollowBpm3",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 999,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p3bpm",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      980,
      460,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 3 bpm"
    }
   },
   {
    "box": {
     "id": "obj-unpack4",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "patching_rect": [
      1100,
      270,
      80,
      22
     ],
     "outlettype": [
      "",
      "",
      ""
     ],
     "text": "unpack 0. 0. 0."
    }
   },
   {
    "box": {
     "id": "obj-n4start",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1100,
      300,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowStart4",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowStart4",
       "parameter_shortname": "FollowStart4",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p4start",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1100,
      400,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 4 start"
    }
   },
   {
    "box": {
     "id": "obj-n4end",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1100,
      330,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowEnd4",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowEnd4",
       "parameter_shortname": "FollowEnd4",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p4end",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1100,
      430,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 4 end"
    }
   },
   {
    "box": {
     "id": "obj-n4bpm",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1100,
      360,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowBpm4",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowBpm4",
       "parameter_shortname": "FollowBpm4",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 999,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p4bpm",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1100,
      460,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 4 bpm"
    }
   },
   {
    "box": {
     "id": "obj-unpack5",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "patching_rect": [
      1220,
      270,
      80,
      22
     ],
     "outlettype": [
      "",
      "",
      ""
     ],
     "text": "unpack 0. 0. 0."
    }
   },
   {
    "box": {
     "id": "obj-n5start",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1220,
      300,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowStart5",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowStart5",
       "parameter_shortname": "FollowStart5",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p5start",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1220,
      400,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 5 start"
    }
   },
   {
    "box": {
     "id": "obj-n5end",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1220,
      330,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowEnd5",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowEnd5",
       "parameter_shortname": "FollowEnd5",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p5end",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1220,
      430,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 5 end"
    }
   },
   {
    "box": {
     "id": "obj-n5bpm",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1220,
      360,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowBpm5",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowBpm5",
       "parameter_shortname": "FollowBpm5",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 999,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p5bpm",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1220,
      460,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 5 bpm"
    }
   },
   {
    "box": {
     "id": "obj-unpack6",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "patching_rect": [
      1340,
      270,
      80,
      22
     ],
     "outlettype": [
      "",
      "",
      ""
     ],
     "text": "unpack 0. 0. 0."
    }
   },
   {
    "box": {
     "id": "obj-n6start",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1340,
      300,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowStart6",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowStart6",
       "parameter_shortname": "FollowStart6",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p6start",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1340,
      400,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 6 start"
    }
   },
   {
    "box": {
     "id": "obj-n6end",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1340,
      330,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowEnd6",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowEnd6",
       "parameter_shortname": "FollowEnd6",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p6end",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1340,
      430,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 6 end"
    }
   },
   {
    "box": {
     "id": "obj-n6bpm",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1340,
      360,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowBpm6",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowBpm6",
       "parameter_shortname": "FollowBpm6",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 999,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p6bpm",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1340,
      460,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 6 bpm"
    }
   },
   {
    "box": {
     "id": "obj-unpack7",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "patching_rect": [
      1460,
      270,
      80,
      22
     ],
     "outlettype": [
      "",
      "",
      ""
     ],
     "text": "unpack 0. 0. 0."
    }
   },
   {
    "box": {
     "id": "obj-n7start",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1460,
      300,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowStart7",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowStart7",
       "parameter_shortname": "FollowStart7",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p7start",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1460,
      400,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 7 start"
    }
   },
   {
    "box": {
     "id": "obj-n7end",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1460,
      330,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowEnd7",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowEnd7",
       "parameter_shortname": "FollowEnd7",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p7end",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1460,
      430,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 7 end"
    }
   },
   {
    "box": {
     "id": "obj-n7bpm",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1460,
      360,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowBpm7",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowBpm7",
       "parameter_shortname": "FollowBpm7",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 999,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p7bpm",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1460,
      460,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 7 bpm"
    }
   },
   {
    "box": {
     "id": "obj-unpack8",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "patching_rect": [
      1580,
      270,
      80,
      22
     ],
     "outlettype": [
      "",
      "",
      ""
     ],
     "text": "unpack 0. 0. 0."
    }
   },
   {
    "box": {
     "id": "obj-n8start",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1580,
      300,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowStart8",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowStart8",
       "parameter_shortname": "FollowStart8",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p8start",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1580,
      400,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 8 start"
    }
   },
   {
    "box": {
     "id": "obj-n8end",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1580,
      330,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowEnd8",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowEnd8",
       "parameter_shortname": "FollowEnd8",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p8end",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1580,
      430,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 8 end"
    }
   },
   {
    "box": {
     "id": "obj-n8bpm",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1580,
      360,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowBpm8",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowBpm8",
       "parameter_shortname": "FollowBpm8",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 999,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p8bpm",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1580,
      460,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 8 bpm"
    }
   },
   {
    "box": {
     "id": "obj-unpack9",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "patching_rect": [
      1700,
      270,
      80,
      22
     ],
     "outlettype": [
      "",
      "",
      ""
     ],
     "text": "unpack 0. 0. 0."
    }
   },
   {
    "box": {
     "id": "obj-n9start",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1700,
      300,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowStart9",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowStart9",
       "parameter_shortname": "FollowStart9",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p9start",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1700,
      400,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 9 start"
    }
   },
   {
    "box": {
     "id": "obj-n9end",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1700,
      330,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowEnd9",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowEnd9",
       "parameter_shortname": "FollowEnd9",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p9end",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1700,
      430,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 9 end"
    }
   },
   {
    "box": {
     "id": "obj-n9bpm",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1700,
      360,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowBpm9",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowBpm9",
       "parameter_shortname": "FollowBpm9",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 999,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p9bpm",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1700,
      460,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 9 bpm"
    }
   },
   {
    "box": {
     "id": "obj-unpack10",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "patching_rect": [
      1820,
      270,
      80,
      22
     ],
     "outlettype": [
      "",
      "",
      ""
     ],
     "text": "unpack 0. 0. 0."
    }
   },
   {
    "box": {
     "id": "obj-n10start",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1820,
      300,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowStart10",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowStart10",
       "parameter_shortname": "FollowStart10",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p10start",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1820,
      400,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 10 start"
    }
   },
   {
    "box": {
     "id": "obj-n10end",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1820,
      330,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowEnd10",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowEnd10",
       "parameter_shortname": "FollowEnd10",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p10end",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1820,
      430,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 10 end"
    }
   },
   {
    "box": {
     "id": "obj-n10bpm",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1820,
      360,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowBpm10",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowBpm10",
       "parameter_shortname": "FollowBpm10",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 999,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p10bpm",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1820,
      460,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 10 bpm"
    }
   },
   {
    "box": {
     "id": "obj-unpack11",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "patching_rect": [
      1940,
      270,
      80,
      22
     ],
     "outlettype": [
      "",
      "",
      ""
     ],
     "text": "unpack 0. 0. 0."
    }
   },
   {
    "box": {
     "id": "obj-n11start",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1940,
      300,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowStart11",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowStart11",
       "parameter_shortname": "FollowStart11",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p11start",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1940,
      400,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 11 start"
    }
   },
   {
    "box": {
     "id": "obj-n11end",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1940,
      330,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowEnd11",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowEnd11",
       "parameter_shortname": "FollowEnd11",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p11end",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1940,
      430,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 11 end"
    }
   },
   {
    "box": {
     "id": "obj-n11bpm",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      1940,
      360,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowBpm11",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowBpm11",
       "parameter_shortname": "FollowBpm11",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 999,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p11bpm",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      1940,
      460,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 11 bpm"
    }
   },
   {
    "box": {
     "id": "obj-unpack12",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "patching_rect": [
      2060,
      270,
      80,
      22
     ],
     "outlettype": [
      "",
      "",
      ""
     ],
     "text": "unpack 0. 0. 0."
    }
   },
   {
    "box": {
     "id": "obj-n12start",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      2060,
      300,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowStart12",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowStart12",
       "parameter_shortname": "FollowStart12",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p12start",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      2060,
      400,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 12 start"
    }
   },
   {
    "box": {
     "id": "obj-n12end",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      2060,
      330,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowEnd12",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowEnd12",
       "parameter_shortname": "FollowEnd12",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p12end",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      2060,
      430,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 12 end"
    }
   },
   {
    "box": {
     "id": "obj-n12bpm",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      2060,
      360,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowBpm12",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowBpm12",
       "parameter_shortname": "FollowBpm12",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 999,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p12bpm",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      2060,
      460,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 12 bpm"
    }
   },
   {
    "box": {
     "id": "obj-unpack13",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "patching_rect": [
      2180,
      270,
      80,
      22
     ],
     "outlettype": [
      "",
      "",
      ""
     ],
     "text": "unpack 0. 0. 0."
    }
   },
   {
    "box": {
     "id": "obj-n13start",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      2180,
      300,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowStart13",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowStart13",
       "parameter_shortname": "FollowStart13",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p13start",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      2180,
      400,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 13 start"
    }
   },
   {
    "box": {
     "id": "obj-n13end",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      2180,
      330,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowEnd13",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowEnd13",
       "parameter_shortname": "FollowEnd13",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p13end",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      2180,
      430,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 13 end"
    }
   },
   {
    "box": {
     "id": "obj-n13bpm",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      2180,
      360,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowBpm13",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowBpm13",
       "parameter_shortname": "FollowBpm13",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 999,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p13bpm",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      2180,
      460,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 13 bpm"
    }
   },
   {
    "box": {
     "id": "obj-unpack14",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "patching_rect": [
      2300,
      270,
      80,
      22
     ],
     "outlettype": [
      "",
      "",
      ""
     ],
     "text": "unpack 0. 0. 0."
    }
   },
   {
    "box": {
     "id": "obj-n14start",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      2300,
      300,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowStart14",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowStart14",
       "parameter_shortname": "FollowStart14",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p14start",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      2300,
      400,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 14 start"
    }
   },
   {
    "box": {
     "id": "obj-n14end",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      2300,
      330,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowEnd14",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowEnd14",
       "parameter_shortname": "FollowEnd14",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p14end",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      2300,
      430,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 14 end"
    }
   },
   {
    "box": {
     "id": "obj-n14bpm",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      2300,
      360,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowBpm14",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowBpm14",
       "parameter_shortname": "FollowBpm14",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 999,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p14bpm",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      2300,
      460,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 14 bpm"
    }
   },
   {
    "box": {
     "id": "obj-unpack15",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 3,
     "patching_rect": [
      2420,
      270,
      80,
      22
     ],
     "outlettype": [
      "",
      "",
      ""
     ],
     "text": "unpack 0. 0. 0."
    }
   },
   {
    "box": {
     "id": "obj-n15start",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      2420,
      300,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowStart15",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowStart15",
       "parameter_shortname": "FollowStart15",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p15start",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      2420,
      400,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 15 start"
    }
   },
   {
    "box": {
     "id": "obj-n15end",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      2420,
      330,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowEnd15",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowEnd15",
       "parameter_shortname": "FollowEnd15",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 1000000,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p15end",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      2420,
      430,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 15 end"
    }
   },
   {
    "box": {
     "id": "obj-n15bpm",
     "maxclass": "live.numbox",
     "numinlets": 1,
     "numoutlets": 2,
     "patching_rect": [
      2420,
      360,
      60,
      15
     ],
     "outlettype": [
      "",
      "float"
     ],
     "varname": "FollowBpm15",
     "parameter_enable": 1,
     "saved_attribute_attributes": {
      "valueof": {
       "parameter_longname": "FollowBpm15",
       "parameter_shortname": "FollowBpm15",
       "parameter_type": 0,
       "parameter_mmin": 0,
       "parameter_mmax": 999,
       "parameter_initial_enable": 1,
       "parameter_initial": [
        0
       ],
       "parameter_invisible": 1,
       "parameter_unitstyle": 0
      }
     }
    }
   },
   {
    "box": {
     "id": "obj-p15bpm",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      2420,
      460,
      110,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "prepend fslot 15 bpm"
    }
   },
   {
    "box": {
     "id": "obj-pfollow",
     "maxclass": "newobj",
     "numinlets": 1,
     "numoutlets": 1,
     "patching_rect": [
      460,
      90,
      90,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "buildreview"
    }
   },
   {
    "box": {
     "id": "obj-init",
     "maxclass": "message",
     "numinlets": 2,
     "numoutlets": 1,
     "patching_rect": [
      700,
      150,
      40,
      22
     ],
     "outlettype": [
      ""
     ],
     "text": "init"
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
     "text": "analyze"
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
     "numoutlets": 5,
     "patching_rect": [
      300,
      280,
      120,
      22
     ],
     "outlettype": [
      "",
      "",
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
     "text": "Click ANALYZE to scan. Song details appear below.",
     "presentation": 1,
     "presentation_rect": [
      8,
      64,
      378,
      22
     ],
     "linecount": 1,
     "fontsize": 10.5
    }
   },
   {
    "box": {
     "id": "obj-resultheading",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      1010,
      20,
      380,
      20
     ],
     "text": "ANALYSIS RESULTS — Title | BPM | Duration | Bar | Warp",
     "presentation": 1,
     "presentation_rect": [
      8,
      89,
      380,
      18
     ],
     "fontface": 1,
     "fontsize": 10
    }
   },
   {
    "box": {
     "id": "obj-rowroute",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 2,
     "patching_rect": [
      1010,
      75,
      90,
      22
     ],
     "text": "route row"
    }
   },
   {
    "box": {
     "id": "obj-indexroute",
     "maxclass": "newobj",
     "numinlets": 2,
     "numoutlets": 17,
     "patching_rect": [
      1010,
      110,
      450,
      22
     ],
     "text": "route 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15"
    }
   },
   {
    "box": {
     "id": "obj-review0",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      1010,
      150,
      380,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      8,
      108,
      378,
      20
     ],
     "text": "",
     "fontsize": 9.5
    }
   },
   {
    "box": {
     "id": "obj-review1",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      1010,
      173,
      380,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      8,
      130,
      378,
      20
     ],
     "text": "",
     "fontsize": 9.5
    }
   },
   {
    "box": {
     "id": "obj-review2",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      1010,
      196,
      380,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      8,
      152,
      378,
      20
     ],
     "text": "",
     "fontsize": 9.5
    }
   },
   {
    "box": {
     "id": "obj-review3",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      1010,
      219,
      380,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      8,
      174,
      378,
      20
     ],
     "text": "",
     "fontsize": 9.5
    }
   },
   {
    "box": {
     "id": "obj-review4",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      1010,
      242,
      380,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      8,
      196,
      378,
      20
     ],
     "text": "",
     "fontsize": 9.5
    }
   },
   {
    "box": {
     "id": "obj-review5",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      1010,
      265,
      380,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      8,
      218,
      378,
      20
     ],
     "text": "",
     "fontsize": 9.5
    }
   },
   {
    "box": {
     "id": "obj-review6",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      1010,
      288,
      380,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      8,
      240,
      378,
      20
     ],
     "text": "",
     "fontsize": 9.5
    }
   },
   {
    "box": {
     "id": "obj-review7",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      1010,
      311,
      380,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      8,
      262,
      378,
      20
     ],
     "text": "",
     "fontsize": 9.5
    }
   },
   {
    "box": {
     "id": "obj-review8",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      1010,
      334,
      380,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      8,
      284,
      378,
      20
     ],
     "text": "",
     "fontsize": 9.5
    }
   },
   {
    "box": {
     "id": "obj-review9",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      1010,
      357,
      380,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      8,
      306,
      378,
      20
     ],
     "text": "",
     "fontsize": 9.5
    }
   },
   {
    "box": {
     "id": "obj-review10",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      1010,
      380,
      380,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      8,
      328,
      378,
      20
     ],
     "text": "",
     "fontsize": 9.5
    }
   },
   {
    "box": {
     "id": "obj-review11",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      1010,
      403,
      380,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      8,
      350,
      378,
      20
     ],
     "text": "",
     "fontsize": 9.5
    }
   },
   {
    "box": {
     "id": "obj-review12",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      1010,
      426,
      380,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      8,
      372,
      378,
      20
     ],
     "text": "",
     "fontsize": 9.5
    }
   },
   {
    "box": {
     "id": "obj-review13",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      1010,
      449,
      380,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      8,
      394,
      378,
      20
     ],
     "text": "",
     "fontsize": 9.5
    }
   },
   {
    "box": {
     "id": "obj-review14",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      1010,
      472,
      380,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      8,
      416,
      378,
      20
     ],
     "text": "",
     "fontsize": 9.5
    }
   },
   {
    "box": {
     "id": "obj-review15",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      1010,
      495,
      380,
      22
     ],
     "presentation": 1,
     "presentation_rect": [
      8,
      438,
      378,
      20
     ],
     "text": "",
     "fontsize": 9.5
    }
   },
   {
    "box": {
     "id": "obj-leadnotice",
     "maxclass": "comment",
     "numinlets": 1,
     "numoutlets": 0,
     "patching_rect": [
      1010,
      550,
      380,
      42
     ],
     "presentation": 1,
     "presentation_rect": [
      8,
      468,
      378,
      35
     ],
     "text": "Activate LEAD manually after BUILD (future beta).",
     "fontsize": 10,
     "linecount": 2
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
      "obj-routeidx",
      0
     ],
     "destination": [
      "obj-unpack0",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-unpack0",
      0
     ],
     "destination": [
      "obj-n0start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n0start",
      0
     ],
     "destination": [
      "obj-p0start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p0start",
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
      "obj-unpack0",
      1
     ],
     "destination": [
      "obj-n0end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n0end",
      0
     ],
     "destination": [
      "obj-p0end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p0end",
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
      "obj-unpack0",
      2
     ],
     "destination": [
      "obj-n0bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n0bpm",
      0
     ],
     "destination": [
      "obj-p0bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p0bpm",
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
      "obj-routeidx",
      1
     ],
     "destination": [
      "obj-unpack1",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-unpack1",
      0
     ],
     "destination": [
      "obj-n1start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n1start",
      0
     ],
     "destination": [
      "obj-p1start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p1start",
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
      "obj-unpack1",
      1
     ],
     "destination": [
      "obj-n1end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n1end",
      0
     ],
     "destination": [
      "obj-p1end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p1end",
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
      "obj-unpack1",
      2
     ],
     "destination": [
      "obj-n1bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n1bpm",
      0
     ],
     "destination": [
      "obj-p1bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p1bpm",
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
      "obj-routeidx",
      2
     ],
     "destination": [
      "obj-unpack2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-unpack2",
      0
     ],
     "destination": [
      "obj-n2start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n2start",
      0
     ],
     "destination": [
      "obj-p2start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p2start",
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
      "obj-unpack2",
      1
     ],
     "destination": [
      "obj-n2end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n2end",
      0
     ],
     "destination": [
      "obj-p2end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p2end",
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
      "obj-unpack2",
      2
     ],
     "destination": [
      "obj-n2bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n2bpm",
      0
     ],
     "destination": [
      "obj-p2bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p2bpm",
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
      "obj-routeidx",
      3
     ],
     "destination": [
      "obj-unpack3",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-unpack3",
      0
     ],
     "destination": [
      "obj-n3start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n3start",
      0
     ],
     "destination": [
      "obj-p3start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p3start",
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
      "obj-unpack3",
      1
     ],
     "destination": [
      "obj-n3end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n3end",
      0
     ],
     "destination": [
      "obj-p3end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p3end",
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
      "obj-unpack3",
      2
     ],
     "destination": [
      "obj-n3bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n3bpm",
      0
     ],
     "destination": [
      "obj-p3bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p3bpm",
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
      "obj-routeidx",
      4
     ],
     "destination": [
      "obj-unpack4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-unpack4",
      0
     ],
     "destination": [
      "obj-n4start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n4start",
      0
     ],
     "destination": [
      "obj-p4start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p4start",
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
      "obj-unpack4",
      1
     ],
     "destination": [
      "obj-n4end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n4end",
      0
     ],
     "destination": [
      "obj-p4end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p4end",
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
      "obj-unpack4",
      2
     ],
     "destination": [
      "obj-n4bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n4bpm",
      0
     ],
     "destination": [
      "obj-p4bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p4bpm",
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
      "obj-routeidx",
      5
     ],
     "destination": [
      "obj-unpack5",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-unpack5",
      0
     ],
     "destination": [
      "obj-n5start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n5start",
      0
     ],
     "destination": [
      "obj-p5start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p5start",
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
      "obj-unpack5",
      1
     ],
     "destination": [
      "obj-n5end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n5end",
      0
     ],
     "destination": [
      "obj-p5end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p5end",
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
      "obj-unpack5",
      2
     ],
     "destination": [
      "obj-n5bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n5bpm",
      0
     ],
     "destination": [
      "obj-p5bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p5bpm",
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
      "obj-routeidx",
      6
     ],
     "destination": [
      "obj-unpack6",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-unpack6",
      0
     ],
     "destination": [
      "obj-n6start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n6start",
      0
     ],
     "destination": [
      "obj-p6start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p6start",
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
      "obj-unpack6",
      1
     ],
     "destination": [
      "obj-n6end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n6end",
      0
     ],
     "destination": [
      "obj-p6end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p6end",
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
      "obj-unpack6",
      2
     ],
     "destination": [
      "obj-n6bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n6bpm",
      0
     ],
     "destination": [
      "obj-p6bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p6bpm",
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
      "obj-routeidx",
      7
     ],
     "destination": [
      "obj-unpack7",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-unpack7",
      0
     ],
     "destination": [
      "obj-n7start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n7start",
      0
     ],
     "destination": [
      "obj-p7start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p7start",
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
      "obj-unpack7",
      1
     ],
     "destination": [
      "obj-n7end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n7end",
      0
     ],
     "destination": [
      "obj-p7end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p7end",
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
      "obj-unpack7",
      2
     ],
     "destination": [
      "obj-n7bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n7bpm",
      0
     ],
     "destination": [
      "obj-p7bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p7bpm",
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
      "obj-routeidx",
      8
     ],
     "destination": [
      "obj-unpack8",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-unpack8",
      0
     ],
     "destination": [
      "obj-n8start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n8start",
      0
     ],
     "destination": [
      "obj-p8start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p8start",
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
      "obj-unpack8",
      1
     ],
     "destination": [
      "obj-n8end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n8end",
      0
     ],
     "destination": [
      "obj-p8end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p8end",
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
      "obj-unpack8",
      2
     ],
     "destination": [
      "obj-n8bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n8bpm",
      0
     ],
     "destination": [
      "obj-p8bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p8bpm",
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
      "obj-routeidx",
      9
     ],
     "destination": [
      "obj-unpack9",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-unpack9",
      0
     ],
     "destination": [
      "obj-n9start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n9start",
      0
     ],
     "destination": [
      "obj-p9start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p9start",
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
      "obj-unpack9",
      1
     ],
     "destination": [
      "obj-n9end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n9end",
      0
     ],
     "destination": [
      "obj-p9end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p9end",
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
      "obj-unpack9",
      2
     ],
     "destination": [
      "obj-n9bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n9bpm",
      0
     ],
     "destination": [
      "obj-p9bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p9bpm",
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
      "obj-routeidx",
      10
     ],
     "destination": [
      "obj-unpack10",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-unpack10",
      0
     ],
     "destination": [
      "obj-n10start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n10start",
      0
     ],
     "destination": [
      "obj-p10start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p10start",
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
      "obj-unpack10",
      1
     ],
     "destination": [
      "obj-n10end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n10end",
      0
     ],
     "destination": [
      "obj-p10end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p10end",
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
      "obj-unpack10",
      2
     ],
     "destination": [
      "obj-n10bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n10bpm",
      0
     ],
     "destination": [
      "obj-p10bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p10bpm",
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
      "obj-routeidx",
      11
     ],
     "destination": [
      "obj-unpack11",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-unpack11",
      0
     ],
     "destination": [
      "obj-n11start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n11start",
      0
     ],
     "destination": [
      "obj-p11start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p11start",
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
      "obj-unpack11",
      1
     ],
     "destination": [
      "obj-n11end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n11end",
      0
     ],
     "destination": [
      "obj-p11end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p11end",
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
      "obj-unpack11",
      2
     ],
     "destination": [
      "obj-n11bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n11bpm",
      0
     ],
     "destination": [
      "obj-p11bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p11bpm",
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
      "obj-routeidx",
      12
     ],
     "destination": [
      "obj-unpack12",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-unpack12",
      0
     ],
     "destination": [
      "obj-n12start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n12start",
      0
     ],
     "destination": [
      "obj-p12start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p12start",
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
      "obj-unpack12",
      1
     ],
     "destination": [
      "obj-n12end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n12end",
      0
     ],
     "destination": [
      "obj-p12end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p12end",
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
      "obj-unpack12",
      2
     ],
     "destination": [
      "obj-n12bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n12bpm",
      0
     ],
     "destination": [
      "obj-p12bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p12bpm",
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
      "obj-routeidx",
      13
     ],
     "destination": [
      "obj-unpack13",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-unpack13",
      0
     ],
     "destination": [
      "obj-n13start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n13start",
      0
     ],
     "destination": [
      "obj-p13start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p13start",
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
      "obj-unpack13",
      1
     ],
     "destination": [
      "obj-n13end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n13end",
      0
     ],
     "destination": [
      "obj-p13end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p13end",
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
      "obj-unpack13",
      2
     ],
     "destination": [
      "obj-n13bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n13bpm",
      0
     ],
     "destination": [
      "obj-p13bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p13bpm",
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
      "obj-routeidx",
      14
     ],
     "destination": [
      "obj-unpack14",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-unpack14",
      0
     ],
     "destination": [
      "obj-n14start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n14start",
      0
     ],
     "destination": [
      "obj-p14start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p14start",
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
      "obj-unpack14",
      1
     ],
     "destination": [
      "obj-n14end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n14end",
      0
     ],
     "destination": [
      "obj-p14end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p14end",
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
      "obj-unpack14",
      2
     ],
     "destination": [
      "obj-n14bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n14bpm",
      0
     ],
     "destination": [
      "obj-p14bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p14bpm",
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
      "obj-routeidx",
      15
     ],
     "destination": [
      "obj-unpack15",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-unpack15",
      0
     ],
     "destination": [
      "obj-n15start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n15start",
      0
     ],
     "destination": [
      "obj-p15start",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p15start",
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
      "obj-unpack15",
      1
     ],
     "destination": [
      "obj-n15end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n15end",
      0
     ],
     "destination": [
      "obj-p15end",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p15end",
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
      "obj-unpack15",
      2
     ],
     "destination": [
      "obj-n15bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-n15bpm",
      0
     ],
     "destination": [
      "obj-p15bpm",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-p15bpm",
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
      "obj-pfollow",
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
      "obj-pfollow",
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
      "obj-thisdev",
      0
     ],
     "destination": [
      "obj-init",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-init",
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
      3
     ],
     "destination": [
      "obj-routeslot",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-routeslot",
      0
     ],
     "destination": [
      "obj-routeidx",
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
   },
   {
    "patchline": {
     "source": [
      "obj-js",
      4
     ],
     "destination": [
      "obj-rowroute",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-rowroute",
      0
     ],
     "destination": [
      "obj-indexroute",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-indexroute",
      0
     ],
     "destination": [
      "obj-review0",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-indexroute",
      1
     ],
     "destination": [
      "obj-review1",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-indexroute",
      2
     ],
     "destination": [
      "obj-review2",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-indexroute",
      3
     ],
     "destination": [
      "obj-review3",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-indexroute",
      4
     ],
     "destination": [
      "obj-review4",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-indexroute",
      5
     ],
     "destination": [
      "obj-review5",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-indexroute",
      6
     ],
     "destination": [
      "obj-review6",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-indexroute",
      7
     ],
     "destination": [
      "obj-review7",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-indexroute",
      8
     ],
     "destination": [
      "obj-review8",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-indexroute",
      9
     ],
     "destination": [
      "obj-review9",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-indexroute",
      10
     ],
     "destination": [
      "obj-review10",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-indexroute",
      11
     ],
     "destination": [
      "obj-review11",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-indexroute",
      12
     ],
     "destination": [
      "obj-review12",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-indexroute",
      13
     ],
     "destination": [
      "obj-review13",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-indexroute",
      14
     ],
     "destination": [
      "obj-review14",
      0
     ]
    }
   },
   {
    "patchline": {
     "source": [
      "obj-indexroute",
      15
     ],
     "destination": [
      "obj-review15",
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
