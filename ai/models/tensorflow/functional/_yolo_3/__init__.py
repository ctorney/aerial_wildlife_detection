'''
    PyTorch implementation of the RetinaNet object detector:
        Lin, Tsung-Yi, et al. "Focal loss for dense object detection." Proceedings of the IEEE international conference on computer vision. 2017.

    Basic implementation forked and adapted from: https://github.com/kuangliu/pytorch-retinanet

    2019 Benjamin Kellenberger
'''


# default options for the model, may be overridden in the custom configuration loaded at runtime
DEFAULT_OPTIONS = {
	"general": {
		"device": "cuda",
		"seed": 1234
	},
	"model": {
		"kwargs": {
			"pretrained": True,
			"alltrain": False,
                        "init_weights": "weights/trained-camera-trap-yolo.h5"
		}
	},
	"train": {
        "width": 864,
        "height": 864,
		"dataLoader": {
			"kwargs": {
				"shuffle": True,
				"batch_size": 1
			}
		},
		"optim": {
			"class": "tensorflow.keras.optimizers.Adam",
			"kwargs": {
				"learning_rate": 1e-7
			}
		},
		"transform": {
			"class": "ai.models.tensorflow.yolo.boundingBoxes.Compose",
			"kwargs": {
				"transforms": [{
						"class": "ai.models.tensorflow.yolo.boundingBoxes.Resize",
						"kwargs": {
							"size": [864, 864]
						}
					},
					{
						"class": "ai.models.tensorflow.yolo.boundingBoxes.RandomHorizontalFlip",
						"kwargs": {
							"p": 0.5
						}
					}
                ]
			}
		},
		"criterion": {
			"class": "ai.models.tensorflow.functional._yolo_3.loss.YoloLoss",
			"kwargs": {
                "NO_OBJECT_SCALE": 1.0,
                "OBJECT_SCALE": 5.0,
                "COORD_SCALE": 4.0,
                "CLASS_SCALE": 2.0
			}
		},
		"ignore_unsure": True
	},
	"inference": {
        "shuffle": False,
        "batch_size": 1,
        "nms_thresh": 0.1,
        "cls_thresh": 0.1,
        "width": 2592,
        "height": 1952,
		"transform": {
			"class": "ai.models.tensorflow.yolo.boundingBoxes.Compose",
			"kwargs": {
				"transforms": [{
						"class": "ai.models.tensorflow.yolo.boundingBoxes.Resize",
						"kwargs": {
							"size": [1952, 2592]
						}
					}
				]
			}
		},
		"dataLoader": {
			"kwargs": {
				"shuffle": False,
				"batch_size": 1
			}
		}
	}
}