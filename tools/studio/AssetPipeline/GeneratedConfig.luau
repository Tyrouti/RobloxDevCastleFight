--!strict
-- Generated from assets/asset-preparation.json; do not edit.
return [==[{
  "schemaVersion": 1,
  "toolVersion": "1.0.0",
  "scene": {
    "sceneId": "castlefight.asset-visual-test.v1",
    "name": "AssetVisualTest",
    "origin": [
      40,
      0,
      0
    ],
    "padSize": [
      14,
      0.25,
      14
    ],
    "rulerHeight": 12,
    "frontCamera": [
      0,
      6,
      -15
    ],
    "angleCamera": [
      11,
      9,
      -15
    ],
    "lightBrightness": 0.15,
    "lightRange": 24
  },
  "equipment": {
    "Sword": {
      "slot": "RightHand",
      "gripName": "Grip",
      "offset": [
        0,
        0,
        0
      ],
      "rotationDegrees": [
        0,
        0,
        -72
      ],
      "referenceHeightStuds": 5
    },
    "Shield": {
      "slot": "LeftHand",
      "gripName": "Handle",
      "offset": [
        0,
        0,
        0
      ],
      "rotationDegrees": [
        0,
        0,
        0
      ],
      "referenceHeightStuds": 5
    },
    "Bow": {
      "slot": "LeftHand",
      "gripName": "Grip",
      "offset": [
        0,
        0,
        0
      ],
      "rotationDegrees": [
        0,
        0,
        0
      ],
      "referenceHeightStuds": 5
    },
    "Staff": {
      "slot": "RightHand",
      "gripName": "Grip",
      "offset": [
        0,
        0,
        0
      ],
      "rotationDegrees": [
        0,
        0,
        0
      ],
      "referenceHeightStuds": 5
    }
  },
  "assets": [
    {
      "assetId": "human_knight",
      "assetType": "unit",
      "faction": "human",
      "sourceModelPath": "assets/models/units/human_knight/model.glb",
      "approvedConcept": {
        "status": "approved",
        "variant": "A",
        "path": "assets/concepts/units/human_knight/variant_A.png",
        "sha256": "a6bb9854af5a7e185581826bab0570ca31dbf76d5c28acfe2bf26a2cc897952b"
      },
      "targetHeightStuds": 5,
      "maxTriangles": 1500,
      "desiredForwardDirection": "-Z",
      "sourceForwardDirection": "-Z",
      "collisionMode": "none",
      "requiresRig": true,
      "characterCategory": "humanoid",
      "equipmentSlots": {
        "RightHand": {
          "position": [
            0.508,
            0.553,
            0.0036
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "LeftHand": {
          "position": [
            -0.508,
            0.553,
            0.0036
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "Back": {
          "position": [
            0,
            0.65,
            0.12
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "Head": {
          "position": [
            0,
            0.92,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "Root": {
          "position": [
            0,
            0,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        }
      },
      "importStatus": "imported_in_test_scene",
      "validationStatus": "requiring_manual_review",
      "maxVisualComponents": 64,
      "plotSizeStuds": null,
      "spawnPoint": null,
      "geometryEvidence": {
        "triangleCount": 1576,
        "reportPath": "assets/models/units/human_knight/inspection/geometry.json",
        "sourceSHA256": "462353370a5e38030e46ee5d74d580fa0557fc8f5ef614c018012f84bcb15a6d",
        "observedMeshIds": [
          "rbxassetid://92061902066137"
        ]
      },
      "notes": "5 studs is the existing visual-test proposal, not game balance. Body lacks sword/shield and rig."
    },
    {
      "assetId": "human_archer",
      "assetType": "unit",
      "faction": "human",
      "sourceModelPath": null,
      "approvedConcept": {
        "status": "approved",
        "variant": "A",
        "path": "assets/concepts/units/human_archer/variant_A.png",
        "sha256": "6b877426c43bd4da2869154d42cce07b30e9d4c71bd7adb38eb7ddcddb116ad8"
      },
      "targetHeightStuds": null,
      "maxTriangles": 1500,
      "desiredForwardDirection": "-Z",
      "sourceForwardDirection": null,
      "collisionMode": "none",
      "requiresRig": true,
      "characterCategory": "humanoid",
      "equipmentSlots": {
        "RightHand": {
          "position": [
            0.45,
            0.55,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "LeftHand": {
          "position": [
            -0.45,
            0.55,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "Back": {
          "position": [
            0,
            0.65,
            0.12
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "Head": {
          "position": [
            0,
            0.92,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "Root": {
          "position": [
            0,
            0,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        }
      },
      "importStatus": "source_missing",
      "validationStatus": "not_prepared",
      "maxVisualComponents": 64,
      "plotSizeStuds": null,
      "spawnPoint": null,
      "geometryEvidence": null,
      "notes": "TODO: source, height, facing and footprint. Slots and exit coordinates are provisional editor markers."
    },
    {
      "assetId": "human_mage",
      "assetType": "unit",
      "faction": "human",
      "sourceModelPath": null,
      "approvedConcept": {
        "status": "approved",
        "variant": "A",
        "path": "assets/concepts/units/human_mage/variant_A.png",
        "sha256": "4b0da39b150bd75bc41b9b80d81e0cc1cccf24970cc4cb668643d05adf6b5722"
      },
      "targetHeightStuds": null,
      "maxTriangles": 1500,
      "desiredForwardDirection": "-Z",
      "sourceForwardDirection": null,
      "collisionMode": "none",
      "requiresRig": true,
      "characterCategory": "humanoid",
      "equipmentSlots": {
        "RightHand": {
          "position": [
            0.45,
            0.55,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "LeftHand": {
          "position": [
            -0.45,
            0.55,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "Back": {
          "position": [
            0,
            0.65,
            0.12
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "Head": {
          "position": [
            0,
            0.92,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "Root": {
          "position": [
            0,
            0,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        }
      },
      "importStatus": "source_missing",
      "validationStatus": "not_prepared",
      "maxVisualComponents": 64,
      "plotSizeStuds": null,
      "spawnPoint": null,
      "geometryEvidence": null,
      "notes": "TODO: source, height, facing and footprint. Slots and exit coordinates are provisional editor markers."
    },
    {
      "assetId": "undead_giant",
      "assetType": "unit",
      "faction": "undead",
      "sourceModelPath": null,
      "approvedConcept": {
        "status": "approved",
        "variant": "B",
        "path": "assets/concepts/units/undead_giant/variant_B.png",
        "sha256": "1280299c990115d9bef06a8157595452a9ef277bf38daa5249688700cc9b1b3f"
      },
      "targetHeightStuds": null,
      "maxTriangles": 2500,
      "desiredForwardDirection": "-Z",
      "sourceForwardDirection": null,
      "collisionMode": "none",
      "requiresRig": true,
      "characterCategory": "giant",
      "equipmentSlots": {
        "RightHand": {
          "position": [
            0.45,
            0.55,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "LeftHand": {
          "position": [
            -0.45,
            0.55,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "Back": {
          "position": [
            0,
            0.65,
            0.12
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "Head": {
          "position": [
            0,
            0.92,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "Root": {
          "position": [
            0,
            0,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        }
      },
      "importStatus": "source_missing",
      "validationStatus": "not_prepared",
      "maxVisualComponents": 64,
      "plotSizeStuds": null,
      "spawnPoint": null,
      "geometryEvidence": null,
      "notes": "TODO: source, height, facing and footprint. Slots and exit coordinates are provisional editor markers."
    },
    {
      "assetId": "undead_skeleton_archer",
      "assetType": "unit",
      "faction": "undead",
      "sourceModelPath": null,
      "approvedConcept": {
        "status": "approved",
        "variant": "A",
        "path": "assets/concepts/units/undead_skeleton_archer/variant_A.png",
        "sha256": "c77b4047da9ed8a0e9ebbd16ee10bf15f6f9d8852ffb442d35130188bab94f02"
      },
      "targetHeightStuds": null,
      "maxTriangles": 1500,
      "desiredForwardDirection": "-Z",
      "sourceForwardDirection": null,
      "collisionMode": "none",
      "requiresRig": true,
      "characterCategory": "skeleton",
      "equipmentSlots": {
        "RightHand": {
          "position": [
            0.45,
            0.55,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "LeftHand": {
          "position": [
            -0.45,
            0.55,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "Back": {
          "position": [
            0,
            0.65,
            0.12
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "Head": {
          "position": [
            0,
            0.92,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "Root": {
          "position": [
            0,
            0,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        }
      },
      "importStatus": "source_missing",
      "validationStatus": "not_prepared",
      "maxVisualComponents": 64,
      "plotSizeStuds": null,
      "spawnPoint": null,
      "geometryEvidence": null,
      "notes": "TODO: source, height, facing and footprint. Slots and exit coordinates are provisional editor markers."
    },
    {
      "assetId": "undead_necromancer",
      "assetType": "unit",
      "faction": "undead",
      "sourceModelPath": null,
      "approvedConcept": {
        "status": "approved",
        "variant": "B",
        "path": "assets/concepts/units/undead_necromancer/variant_B.png",
        "sha256": "d6b9583675ed956a7c3c3dc883ac0d1da902e9a8b912ffaa485af4403c15b49b"
      },
      "targetHeightStuds": null,
      "maxTriangles": 1500,
      "desiredForwardDirection": "-Z",
      "sourceForwardDirection": null,
      "collisionMode": "none",
      "requiresRig": true,
      "characterCategory": "skeleton",
      "equipmentSlots": {
        "RightHand": {
          "position": [
            0.45,
            0.55,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "LeftHand": {
          "position": [
            -0.45,
            0.55,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "Back": {
          "position": [
            0,
            0.65,
            0.12
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "Head": {
          "position": [
            0,
            0.92,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        },
        "Root": {
          "position": [
            0,
            0,
            0
          ],
          "rotationDegrees": [
            0,
            0,
            0
          ]
        }
      },
      "importStatus": "source_missing",
      "validationStatus": "not_prepared",
      "maxVisualComponents": 64,
      "plotSizeStuds": null,
      "spawnPoint": null,
      "geometryEvidence": null,
      "notes": "TODO: source, height, facing and footprint. Slots and exit coordinates are provisional editor markers."
    },
    {
      "assetId": "human_barracks",
      "assetType": "building",
      "faction": "human",
      "sourceModelPath": null,
      "approvedConcept": {
        "status": "approved",
        "variant": "B",
        "path": "assets/concepts/buildings/human_barracks/variant_B.png",
        "sha256": "db9d31f978614032733b9a3b7e3ee13011d4de1578a994482413340d707f8dfc"
      },
      "targetHeightStuds": null,
      "maxTriangles": 2500,
      "desiredForwardDirection": "-Z",
      "sourceForwardDirection": null,
      "collisionMode": "box",
      "requiresRig": false,
      "characterCategory": null,
      "equipmentSlots": {},
      "importStatus": "source_missing",
      "validationStatus": "not_prepared",
      "maxVisualComponents": 64,
      "plotSizeStuds": null,
      "spawnPoint": {
        "positionNormalized": [
          0,
          0,
          -0.65
        ],
        "rotationDegrees": [
          0,
          0,
          0
        ],
        "provisional": true
      },
      "geometryEvidence": null,
      "notes": "TODO: source, height, facing and footprint. Slots and exit coordinates are provisional editor markers."
    },
    {
      "assetId": "human_archer_tower",
      "assetType": "building",
      "faction": "human",
      "sourceModelPath": null,
      "approvedConcept": null,
      "targetHeightStuds": null,
      "maxTriangles": 2500,
      "desiredForwardDirection": "-Z",
      "sourceForwardDirection": null,
      "collisionMode": "box",
      "requiresRig": false,
      "characterCategory": null,
      "equipmentSlots": {},
      "importStatus": "source_missing",
      "validationStatus": "not_prepared",
      "maxVisualComponents": 64,
      "plotSizeStuds": null,
      "spawnPoint": {
        "positionNormalized": [
          0,
          0,
          -0.65
        ],
        "rotationDegrees": [
          0,
          0,
          0
        ],
        "provisional": true
      },
      "geometryEvidence": null,
      "notes": "TODO: source, height, facing and footprint. Slots and exit coordinates are provisional editor markers."
    },
    {
      "assetId": "human_mage_academy",
      "assetType": "building",
      "faction": "human",
      "sourceModelPath": null,
      "approvedConcept": null,
      "targetHeightStuds": null,
      "maxTriangles": 2500,
      "desiredForwardDirection": "-Z",
      "sourceForwardDirection": null,
      "collisionMode": "box",
      "requiresRig": false,
      "characterCategory": null,
      "equipmentSlots": {},
      "importStatus": "source_missing",
      "validationStatus": "not_prepared",
      "maxVisualComponents": 64,
      "plotSizeStuds": null,
      "spawnPoint": {
        "positionNormalized": [
          0,
          0,
          -0.65
        ],
        "rotationDegrees": [
          0,
          0,
          0
        ],
        "provisional": true
      },
      "geometryEvidence": null,
      "notes": "TODO: source, height, facing and footprint. Slots and exit coordinates are provisional editor markers."
    },
    {
      "assetId": "human_light_sanctuary",
      "assetType": "building",
      "faction": "human",
      "sourceModelPath": null,
      "approvedConcept": null,
      "targetHeightStuds": null,
      "maxTriangles": 2500,
      "desiredForwardDirection": "-Z",
      "sourceForwardDirection": null,
      "collisionMode": "box",
      "requiresRig": false,
      "characterCategory": null,
      "equipmentSlots": {},
      "importStatus": "source_missing",
      "validationStatus": "not_prepared",
      "maxVisualComponents": 64,
      "plotSizeStuds": null,
      "spawnPoint": {
        "positionNormalized": [
          0,
          0,
          -0.65
        ],
        "rotationDegrees": [
          0,
          0,
          0
        ],
        "provisional": true
      },
      "geometryEvidence": null,
      "notes": "TODO: source, height, facing and footprint. Slots and exit coordinates are provisional editor markers."
    },
    {
      "assetId": "undead_giant_graveyard",
      "assetType": "building",
      "faction": "undead",
      "sourceModelPath": null,
      "approvedConcept": null,
      "targetHeightStuds": null,
      "maxTriangles": 2500,
      "desiredForwardDirection": "-Z",
      "sourceForwardDirection": null,
      "collisionMode": "box",
      "requiresRig": false,
      "characterCategory": null,
      "equipmentSlots": {},
      "importStatus": "source_missing",
      "validationStatus": "not_prepared",
      "maxVisualComponents": 64,
      "plotSizeStuds": null,
      "spawnPoint": {
        "positionNormalized": [
          0,
          0,
          -0.65
        ],
        "rotationDegrees": [
          0,
          0,
          0
        ],
        "provisional": true
      },
      "geometryEvidence": null,
      "notes": "TODO: source, height, facing and footprint. Slots and exit coordinates are provisional editor markers."
    },
    {
      "assetId": "undead_bone_tower",
      "assetType": "building",
      "faction": "undead",
      "sourceModelPath": null,
      "approvedConcept": null,
      "targetHeightStuds": null,
      "maxTriangles": 2500,
      "desiredForwardDirection": "-Z",
      "sourceForwardDirection": null,
      "collisionMode": "box",
      "requiresRig": false,
      "characterCategory": null,
      "equipmentSlots": {},
      "importStatus": "source_missing",
      "validationStatus": "not_prepared",
      "maxVisualComponents": 64,
      "plotSizeStuds": null,
      "spawnPoint": {
        "positionNormalized": [
          0,
          0,
          -0.65
        ],
        "rotationDegrees": [
          0,
          0,
          0
        ],
        "provisional": true
      },
      "geometryEvidence": null,
      "notes": "TODO: source, height, facing and footprint. Slots and exit coordinates are provisional editor markers."
    },
    {
      "assetId": "undead_necromancer_crypt",
      "assetType": "building",
      "faction": "undead",
      "sourceModelPath": null,
      "approvedConcept": null,
      "targetHeightStuds": null,
      "maxTriangles": 2500,
      "desiredForwardDirection": "-Z",
      "sourceForwardDirection": null,
      "collisionMode": "box",
      "requiresRig": false,
      "characterCategory": null,
      "equipmentSlots": {},
      "importStatus": "source_missing",
      "validationStatus": "not_prepared",
      "maxVisualComponents": 64,
      "plotSizeStuds": null,
      "spawnPoint": {
        "positionNormalized": [
          0,
          0,
          -0.65
        ],
        "rotationDegrees": [
          0,
          0,
          0
        ],
        "provisional": true
      },
      "geometryEvidence": null,
      "notes": "TODO: source, height, facing and footprint. Slots and exit coordinates are provisional editor markers."
    },
    {
      "assetId": "undead_cursed_obelisk",
      "assetType": "building",
      "faction": "undead",
      "sourceModelPath": null,
      "approvedConcept": null,
      "targetHeightStuds": null,
      "maxTriangles": 2500,
      "desiredForwardDirection": "-Z",
      "sourceForwardDirection": null,
      "collisionMode": "box",
      "requiresRig": false,
      "characterCategory": null,
      "equipmentSlots": {},
      "importStatus": "source_missing",
      "validationStatus": "not_prepared",
      "maxVisualComponents": 64,
      "plotSizeStuds": null,
      "spawnPoint": {
        "positionNormalized": [
          0,
          0,
          -0.65
        ],
        "rotationDegrees": [
          0,
          0,
          0
        ],
        "provisional": true
      },
      "geometryEvidence": null,
      "notes": "TODO: source, height, facing and footprint. Slots and exit coordinates are provisional editor markers."
    },
    {
      "assetId": "human_castle",
      "assetType": "castle",
      "faction": "human",
      "sourceModelPath": null,
      "approvedConcept": null,
      "targetHeightStuds": null,
      "maxTriangles": 5000,
      "desiredForwardDirection": "-Z",
      "sourceForwardDirection": null,
      "collisionMode": "box",
      "requiresRig": false,
      "characterCategory": null,
      "equipmentSlots": {},
      "importStatus": "source_missing",
      "validationStatus": "not_prepared",
      "maxVisualComponents": 64,
      "plotSizeStuds": null,
      "spawnPoint": {
        "positionNormalized": [
          0,
          0,
          -0.65
        ],
        "rotationDegrees": [
          0,
          0,
          0
        ],
        "provisional": true
      },
      "geometryEvidence": null,
      "notes": "TODO: source, height, facing and footprint. Slots and exit coordinates are provisional editor markers."
    },
    {
      "assetId": "undead_castle",
      "assetType": "castle",
      "faction": "undead",
      "sourceModelPath": null,
      "approvedConcept": null,
      "targetHeightStuds": null,
      "maxTriangles": 5000,
      "desiredForwardDirection": "-Z",
      "sourceForwardDirection": null,
      "collisionMode": "box",
      "requiresRig": false,
      "characterCategory": null,
      "equipmentSlots": {},
      "importStatus": "source_missing",
      "validationStatus": "not_prepared",
      "maxVisualComponents": 64,
      "plotSizeStuds": null,
      "spawnPoint": {
        "positionNormalized": [
          0,
          0,
          -0.65
        ],
        "rotationDegrees": [
          0,
          0,
          0
        ],
        "provisional": true
      },
      "geometryEvidence": null,
      "notes": "TODO: source, height, facing and footprint. Slots and exit coordinates are provisional editor markers."
    }
  ]
}]==]
