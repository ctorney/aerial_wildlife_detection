# Configure the built-in models

AIde comes with a number of built-in models for both the AI model and the ranker. These are, to a certain extent, customizable, which we will discuss below.  If you instead wish to completely write your own module(s) for modeling and/or ranking, you can do so by referring to the instructions [here](custom_model.md).


## AI models

AIde ships with the following AI models built in:
* Classification:
  * `ai.models.pytorch.labels.ResNet` ([Kaiming et al., 2015](https://arxiv.org/abs/1512.03385)).
* Object detection:
  * Points:
    * `ai.models.pytorch.points.WSODPointModel`
	([Kellenberger et al., 2019](http://openaccess.thecvf.com/content_CVPRW_2019/papers/EarthVision/Kellenberger_When_a_Few_Clicks_Make_All_the_Difference_Improving_Weakly-Supervised_CVPRW_2019_paper.pdf)).
	  Note that this model is special insofar as it accepts both spatially explicit point annotations as well as image-wide classification labels for training. In the second case, the model requires images where the label class is both present and completely absent in order to be able to localize the class objects. Also, the objects should be of similar size throughout the images. See the [paper](http://openaccess.thecvf.com/content_CVPRW_2019/papers/EarthVision/Kellenberger_When_a_Few_Clicks_Make_All_the_Difference_Improving_Weakly-Supervised_CVPRW_2019_paper.pdf) for details.
  * Bounding boxes:
  	* `ai.models.pytorch.boundingBoxes.RetinaNet` ([Lin, Tsung-Yi, 2017](https://arxiv.org/abs/1708.02002), based on the [implementation by Kuangliu](https://github.com/kuangliu/pytorch-retinanet)).

All models are implemented using [PyTorch](https://pytorch.org/) and support a number of configuration parameters.

To use and configure one of the built-in AI models:
1. Create a JSON file with your custom settings for the model. The default settings per model are outlined below.
2. Provide the correct details in the [configuration *.ini file](configure_settings.md).
For example, to use ResNet for image classification:
```ini
[AIController]

model_lib_path = ai.models.pytorch.ResNet         # replace value with the code string of the model you wish to use
model_options_path = /path/to/your/settings.json  # replace with the JSON file path
```


### Default model settings

This section presents the default parameters for each of the built-in models. You may use these as a template for your JSON file to override parameters.

Notes:
* Not all of the arguments specified in the defaults are required. If an argument (or argument block) is missing in your custom JSON file, it will be replaced with the defaults listed below.
* Any entry named `kwargs` accepts all arguments of the respective Python class (given by the `class` specifier in the same JSON block). For example, you could add the keyword `eps` to the `kwargs` entry of the `optim` section, since this is a valid parameter for e.g. the [Adam optimizer](https://pytorch.org/docs/stable/optim.html#torch.optim.Adam).
* You can further provide custom class executable paths. For example, to add a custom transform function:
    1. Create a new package on the Python path, such as `custom.transforms`.
    2. In your package, add a file with a certain name (e.g. `classificationTransforms.py`). In there, write down your custom class definition (e.g. `MyCustomTransform`).
    3. Link to your custom class by adding the following block to the JSON entry at the right position:
    ```json
    {
        "class": "custom.transforms.classificationTransforms.MyCustomTransform",
        "kwargs": {}
    }
    ```
    Again, `kwargs` is optional, but may contain key-value pairs of class constructor arguments for your custom class.


#### Classification (labels)

##### ResNet

```json
{
	"general": {
		"image_size": [224, 224],
		"device": "cuda",
        "seed": 0
	},
	"model": {
        "kwargs": {
			"featureExtractor": "resnet50",
			"pretrained": true
		}
	},
    "dataset": {
		"class": "ai.models.pytorch.LabelsDataset"
	},
	"train": {
        "dataLoader": {
            "kwargs": {
                "shuffle": true,
                "batch_size": 32
            }
        },
		"optim": {
			"class": "torch.optim.Adam",
			"kwargs": {
				"lr": 1e-7,
				"weight_decay": 0.0
			}
		},
        "transform": {
			"class": "torchvision.transforms.Compose",
			"kwargs": {
				"transforms": [{
						"class": "torchvision.transforms.Resize",
						"kwargs": {
							"size": [224, 224]
						}
					},
					{
						"class": "torchvision.transforms.RandomHorizontalFlip",
						"kwargs": {
							"p": 0.5
						}
					},
					{
                        "class": "torchvision.transforms.ToTensor"
                    },
                    {
                        "class": "torchvision.transforms.Normalize",
                        "kwargs": {
                            "mean": [0.485, 0.456, 0.406],
                            "std": [0.229, 0.224, 0.225]
                        }
                    }
				]
			}
		},
        "criterion": {
			"class": "torch.nn.CrossEntropyLoss"
		},
        "ignore_unsure": true
	},
	"inference": {
		"transform": {
			"class": "torchvision.transforms.Compose",
			"kwargs": {
				"transforms": [{
                        "class": "torchvision.transforms.Resize",
                        "kwargs": {
                            "size": [224, 224]
                        }
                    },
                    {
                        "class": "torchvision.transforms.ToTensor"
                    },
                    {
                        "class": "torchvision.transforms.Normalize",
                        "kwargs": {
                            "mean": [0.485, 0.456, 0.406],
                            "std": [0.229, 0.224, 0.225]
                        }
                    }
				]
			}
		},
		"dataLoader": {
            "kwargs": {
                "shuffle": false,
                "batch_size": 32
            }
        }
	}
}
```


#### Detection (points)

##### Heatmap model (Kellenberger et al., 2019)

```json
{
	"general": {
		"image_size": [800, 600],
		"device": "cuda",
        "seed": 0
	},
	"model": {
        "kwargs": {
			"featureExtractor": "resnet50",
			"pretrained": true
		}
	},
    "dataset": {
		"class": "ai.models.pytorch.PointsDataset"
	},
	"train": {
        "dataLoader": {
            "kwargs": {
                "shuffle": true,
                "batch_size": 1
            }
        },
		"optim": {
			"class": "torch.optim.Adam",
			"kwargs": {
				"lr": 1e-7,
				"weight_decay": 0.0
			}
		},
        "transform": {
			"class": "ai.models.pytorch.points.Compose",
			"kwargs": {
				"transforms": [{
						"class": "ai.models.pytorch.points.Resize",
						"kwargs": {
							"size": [800, 600]
						}
					},
					{
						"class": "ai.models.pytorch.points.RandomHorizontalFlip",
						"kwargs": {
							"p": 0.5
						}
					},
					{
						"class": "ai.models.pytorch.points.DefaultTransform",
						"kwargs": {
							"transform": {
								"class": "torchvision.transforms.ColorJitter",
								"kwargs": {
									"brightness": 0.25,
									"contrast": 0.25,
									"saturation": 0.25,
									"hue": 0.01
								}
							}
						}
					},
					{
						"class": "ai.models.pytorch.points.DefaultTransform",
						"kwargs": {
							"transform": {
								"class": "torchvision.transforms.ToTensor"
							}
						}
					},
					{
						"class": "ai.models.pytorch.points.DefaultTransform",
						"kwargs": {
							"transform": {
								"class": "torchvision.transforms.Normalize",
								"kwargs": {
									"mean": [0.485, 0.456, 0.406],
									"std": [0.229, 0.224, 0.225]
								}
							}
						}
					}
				]
			}
		},
        "criterion": {
			"class": "ai.models.pytorch.functional._wsodPoints.loss.PointsLoss",
			"kwargs": {
				"background_weight": 1.0
			}
		},
        "ignore_unsure": true
	},
	"inference": {
		"transform": {
			"class": "ai.models.pytorch.points.Compose",
			"kwargs": {
				"transforms": [{
						"class": "ai.models.pytorch.points.Resize",
						"kwargs": {
							"size": [800, 600]
						}
					},
					{
						"class": "ai.models.pytorch.points.DefaultTransform",
						"kwargs": {
							"transform": {
								"class": "torchvision.transforms.ToTensor"
							}
						}
					},
					{
						"class": "ai.models.pytorch.points.DefaultTransform",
						"kwargs": {
							"transform": {
								"class": "torchvision.transforms.Normalize",
								"kwargs": {
									"mean": [0.485, 0.456, 0.406],
									"std": [0.229, 0.224, 0.225]
								}
							}
						}
					}
				]
			}
		},
		"dataLoader": {
            "kwargs": {
                "shuffle": false,
                "batch_size": 1
            }
        }
	}
}
```


#### Detection (boundingBoxes)

##### RetinaNet

```json
{
	"general": {
		"image_size": [800, 600],
		"device": "cuda",
		"seed": 1234
	},
	"model": {
		"kwargs": {
			"backbone": "resnet50",
			"pretrained": false,
			"out_planes": 256,
			"convertToInstanceNorm": false
		}
	},
	"train": {
		"dataLoader": {
			"kwargs": {
				"shuffle": true,
				"batch_size": 32
			}
		},
		"optim": {
			"class": "torch.optim.Adam",
			"kwargs": {
				"lr": 1e-7,
				"weight_decay": 0.0
			}
		},
		"transform": {
			"class": "ai.models.pytorch.boundingBoxes.Compose",
			"kwargs": {
				"transforms": [{
						"class": "ai.models.pytorch.boundingBoxes.Resize",
						"kwargs": {
							"size": [800, 600]
						}
					},
					{
						"class": "ai.models.pytorch.boundingBoxes.RandomHorizontalFlip",
						"kwargs": {
							"p": 0.5
						}
					},
					{
						"class": "ai.models.pytorch.boundingBoxes.DefaultTransform",
						"kwargs": {
							"transform": {
								"class": "torchvision.transforms.ColorJitter",
								"kwargs": {
									"brightness": 0.25,
									"contrast": 0.25,
									"saturation": 0.25,
									"hue": 0.01
								}
							}
						}
					},
					{
						"class": "ai.models.pytorch.boundingBoxes.DefaultTransform",
						"kwargs": {
							"transform": {
								"class": "torchvision.transforms.ToTensor"
							}
						}
					},
					{
						"class": "ai.models.pytorch.boundingBoxes.DefaultTransform",
						"kwargs": {
							"transform": {
								"class": "torchvision.transforms.Normalize",
								"kwargs": {
									"mean": [0.485, 0.456, 0.406],
									"std": [0.229, 0.224, 0.225]
								}
							}
						}
					}
				]
			}
		},
		"criterion": {
			"class": "ai.models.pytorch.functional._retinanet.loss.FocalLoss",
			"kwargs": {
				"gamma": 2.0,
				"alpha": 0.25,
				"background_weight": 1.0
			}
		},
		"ignore_unsure": true
	},
	"inference": {
		"num_predictions_max": 128,
		"transform": {
			"class": "ai.models.pytorch.boundingBoxes.Compose",
			"kwargs": {
				"transforms": [{
						"class": "ai.models.pytorch.boundingBoxes.Resize",
						"kwargs": {
							"size": [800, 600]
						}
					},
					{
						"class": "ai.models.pytorch.boundingBoxes.DefaultTransform",
						"kwargs": {
							"transform": {
								"class": "torchvision.transforms.ToTensor"
							}
						}
					},
					{
						"class": "ai.models.pytorch.boundingBoxes.DefaultTransform",
						"kwargs": {
							"transform": {
								"class": "torchvision.transforms.Normalize",
								"kwargs": {
									"mean": [0.485, 0.456, 0.406],
									"std": [0.229, 0.224, 0.225]
								}
							}
						}
					}
				]
			}
		},
		"dataLoader": {
			"kwargs": {
				"shuffle": false,
				"batch_size": 32
			}
		}
	}
}
```

**New since January 29, 2020:** RetinaNet now supports the argument "num_predictions_max" for inference to limit the number of predicted bounding boxes per image (only those bounding boxes with the highest confidence values are retained). This is highly recommended, especially for cases where a model is trained from scratch; an untrained RetinaNet might quickly predict >40.000 objects, which becomes impossible to handle. The default limit in the number of bounding boxes is 128, but this value can be customized here accordingly.



### About object detection transforms

For object detection (i.e., points and bounding boxes), certain transforms naturally should not be carried out on the image alone. For example, random horizontal flips affect both the image and the labeled points or bounding boxes.

AIde therefore applies transforms to the image, points/bounding boxes, and class labels. This means that object detection models, such as `RetinaNet`, only accept one of the following transforms as a top-level transform object:

* `ai.models.pytorch.boundingBoxes.Compose`
  Accepts an iterable of custom, detection-ready transforms and applies them in order.

  Args:
  * transforms (iterable): Iterable (list, tuple, etc.) of transforms from this list here.


* `ai.models.pytorch.boundingBoxes.DefaultTransform`
  Receives one of the standard PyTorch transforms (e.g. from `torchvision.transforms`) and, at runtime, applies it to the image or tensor only (not to bounding boxes or labels). This is useful for image manipulations that do not result in a geometric change, such as color distortions.

  Args:
  * transform: a callable object that works on either PIL images or torch tensors, depending on where in the transform stack the 'DefaultTransform' is inserted.


* `ai.models.pytorch.boundingBoxes.Resize`
  Resize an image and associated bounding boxes to a given size.

  Args:
  * size (sequence or int): int (square side) or iterable of size 2 (width, height) denoting the image's absolute target size.
  * interpolation (int, optional): Desired interpolation. Default is ``PIL.Image.BILINEAR``.


* `ai.models.pytorch.boundingBoxes.RandomHorizontalFlip`
  Horizontally flip the given PIL Image and bounding boxes randomly with a given probability.

  Args:
  * p (float): probability of the image and boxes being flipped. Default value is 0.5


* `ai.models.pytorch.boundingBoxes.RandomFlip`
  Horizontally and/or vertically flip the given PIL Image and bounding boxes randomly with a given probability.

  Args:
  * p_h (float): probability of the image and boxes being flipped horizontally. Default value is 0.5
  * p_v (float): probability of the image and boxes being flipped vertically. Default value is 0.5


* `ai.models.pytorch.boundingBoxes.RandomClip`
  Random image clip of fixed size with custom properties.

  Args:
  * patchSize (sequence or int): int (square side) or iterable of size 2 (width, height) denoting the size of the patch to be clipped from the full image
  * jitter (sequence, int or float): int, float (both directions) or iterable (x, y) denoting the maximum pixel values that are randomly added or subtracted to the X and Y coordinates of the patch center. Useful to maximize variability.
  * limitBorders (boolean): boolean. If True, patches are always fully inside the parent image and never exceed its boundaries.
  * objectProbability (float): either a scalar in [0, 1], or None.
                       If a scalar value is chosen, the patch will be clipped with position from one of the label bounding boxes (if available) at random, under the condition that a uniform, random value is <= this scalar.
                       If set to None, the patch will be clipped completely at random.


* `ai.models.pytorch.boundingBoxes.RandomSizedClip`
  Random image clip with custom size and custom properties. Similar to `ai.models.pytorch.boundingBoxes.RandomClip`, but with two additional parameters.
  
  Args:
  * patchSizeMin (sequence or int): int (square side) or iterable of size 2 (width, height) denoting the minimum patch size to be clipped
  * patchSizeMax (sequence or int): int (square side) or iterable of size 2 (width, height) denoting the maximum patch size to be clipped
  * jitter (sequence, int or float)
  * limitBorders (boolean)
  * objectProbability (float)


Similarly, point models have an identical set of transforms; for these cases simply replace the substring `ai.models.pytorch.boundingBoxes` with `ai.models.pytorch.points`.
