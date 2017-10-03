//
//  globals.h
//  3DIMC
//
//  Created by Raul Catena on 1/19/17.
//  Copyright © 2017 University of Zürich. All rights reserved.
//

#ifndef globals_h
#define globals_h

#define METADATA_GIVEN_COLUMNS_OFFSET 3
#define METADATA_GIVEN_COLUMNS @[@"Image", @"Hash", @"Relative path"];

#define TAB_ID_BLEND @"1"
#define TAB_ID_TILES @"2"
#define TAB_ID_METAD @"3"
#define TAB_ID_DATAT @"4"
#define TAB_ID_PLOTS @"5"
#define TAB_ID_THREED @"6"
#define TAB_ID_ANALYTICS @"7"

//JSON KEYS
#define JSON_DICT_FILES @"json_dict_files"
#define JSON_DICT_FILE_ORDER @"json_dict_file_order"
#define JSON_DICT_METADATA_LABELS @"json_dict_metadata_labels"

#define JSON_DICT_ITEM_NAME @"json_dict_item_name"
#define JSON_DICT_ITEM_SUBNAME @"json_dict_item_subname"
#define JSON_DICT_ITEM_HASH @"json_dict_item_hash"
#define JSON_DICT_ITEM_RELPATH @"json_dict_item_relpath"
#define JSON_DICT_ITEM_ABSPATH @"json_dict_item_abspath"
#define JSON_DICT_ITEM_FILETYPE @"json_dict_item_filetype"
#define JSON_DICT_ITEM_SECOND_RELPATH @"json_dict_item_second_relpath"
#define JSON_DICT_ITEM_SECOND_ABSPATH @"json_dict_item_second_abspath"
#define JSON_DICT_ITEM_SECOND_FILETYPE @"json_dict_item_second_filetype"

#define JSON_DICT_FILE_IS_LOADED @"json_dict_file_is_loaded"
#define JSON_DICT_FILE_IS_SOFT_LOADED @"json_dict_file_is_soft_loaded"
#define JSON_DICT_FILE_CONTAINERS @"json_dict_file_containers"

#define JSON_DICT_CONT_IS_PANORAMA @"json_dict_cont_is_panorama"
#define JSON_DICT_CONT_PANORAMA_NAME @"json_dict_cont_panorama_name"
#define JSON_DICT_CONT_PANORAMA_W @"json_dict_cont_panorama_w"
#define JSON_DICT_CONT_PANORAMA_H @"json_dict_cont_panorama_h"
#define JSON_DICT_CONT_PANORAMA_COEF @"json_dict_cont_panorama_coef"
#define JSON_DICT_CONT_PANORAMA_IMAGES @"json_dict_cont_panorama_images"

#define JSON_DICT_IMAGE_CHANNELS @"json_dict_image_channels"
#define JSON_DICT_IMAGE_CHANNEL_SETTINGS @"json_dict_image_channel_settings"
#define JSON_DICT_IMAGE_ORIG_CHANNELS @"json_dict_image_orig_channels"
#define JSON_DICT_IMAGE_NAME @"json_dict_image_name"
#define JSON_DICT_IMAGE_W @"json_dict_image_w"
#define JSON_DICT_IMAGE_H @"json_dict_image_h"
#define JSON_DICT_IMAGE_RECT_IN_PAN @"json_dict_image_rect_in_pan"
#define JSON_DICT_IMAGE_TRANSFORM @"json_dict_image_transform"
#define JSON_DICT_IMAGE_ORDER_INDEX @"json_dict_image_order_index"
#define JSON_DICT_IMAGE_ROI_INDEX @"json_dict_image_roi_index"
#define JSON_DICT_IMAGE_ALLDATA @"json_dict_image_alldata"
#define JSON_DICT_IMAGE_METADATA @"json_dict_image_metadata"

#define JSON_DICT_PIXEL_TRAININGS @"json_dict_pixel_trainings"
#define JSON_DICT_PIXEL_TRAINING_NAME @"json_dict_pixel_training_name"
#define JSON_DICT_PIXEL_TRAINING_LABELS @"json_dict_pixel_training_labels"
#define JSON_DICT_PIXEL_TRAINING_IS_SEGMENTATION @"json_dict_pixel_training_is_segmentation"
#define JSON_DICT_PIXEL_TRAINING_LEARNING_SETTINGS @"json_dict_training_learning_settings"

#define JSON_DICT_PIXEL_MAPS @"json_dict_pixel_maps"
#define JSON_DICT_PIXEL_MAP_CHANNELS @"json_dict_pixel_map_channels"
#define JSON_DICT_PIXEL_MAP_WHICH_TRAINING @"json_dict_pixel_which_training"
#define JSON_DICT_PIXEL_MAP_FOR_SEGMENTATION @"json_dict_pixel_map_for_segmentation"

#define JSON_DICT_PIXEL_MASKS @"json_dict_masks"
#define JSON_DICT_PIXEL_MASK_IS_CELL @"json_dict_mask_is_cell"
#define JSON_DICT_PIXEL_MASK_IS_NUCLEAR @"json_dict_mask_is_nuclear"
#define JSON_DICT_PIXEL_MASK_IS_DUAL @"json_dict_mask_is_dual"
#define JSON_DICT_PIXEL_MASK_IS_DESIGNATED @"json_dict_mask_is_designated"
#define JSON_DICT_PIXEL_MASK_WHICH_MAP @"json_dict_mask_which_map"
#define JSON_DICT_PIXEL_MASK_IS_PAINTED @"json_dict_mask_is_painted"
#define JSON_DICT_PIXEL_MASK_IS_THRESHOLD @"json_dict_mask_is_threshold"
#define JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS @"json_dict_mask_threshold_settings"
#define JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_THRESHOLD @"threshold"
#define JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_CHANNEL @"channel_index"
#define JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_FRAMER @"framer_index"
#define JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_FLATTEN @"flatten"
#define JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_GAUSSIAN @"gaussian"
#define JSON_DICT_PIXEL_MASK_THRESHOLD_SETTINGS_INVERSE @"inverse"

#define JSON_DICT_PIXEL_MASK_COMPUTATIONS @"json_dict_mask_computations"
#define JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA @"json_dict_mask_computation_metadata"
#define JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_UNITS @"json_dict_mask_computation_metadata_segmented_units"
#define JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_CHANNELS @"json_dict_mask_computation_metadata_segmented_channels"
#define JSON_DICT_PIXEL_MASK_COMPUTATION_METADATA_SEGMENTED_ORIG_CHANNELS @"json_dict_mask_computation_metadata_segmented_orig_channels"
#define JSON_DICT_PIXEL_MASK_COMPUTATION_TRAININGS @"json_dict_mask_computation_trainings"

#define JSON_DICT_PIXEL_MASK_TRAINING_TRAINED @"trained_labels_and_cell_ids"
#define JSON_DICT_PIXEL_MASK_TRAINING_LABELS @"trained_labels_verbose"
#define JSON_DICT_PIXEL_MASK_TRAINING_USE_CHANNELS @"trained_use_channels"

#define JSON_DICT_CHANNEL_SETTINGS_MAXOFFSET @"json_dict_channel_settings_maxoffset"
#define JSON_DICT_CHANNEL_SETTINGS_OFFSET @"json_dict_channel_settings_offset"
#define JSON_DICT_CHANNEL_SETTINGS_MULTIPLIER @"json_dict_channel_settings_multiplier"
#define JSON_DICT_CHANNEL_SETTINGS_SPF @"json_dict_channel_settings_spf"
#define JSON_DICT_CHANNEL_SETTINGS_COLOR @"json_dict_channel_settings_color"
#define JSON_DICT_CHANNEL_SETTINGS_TRANSFORM @"json_dict_channel_settings_transform"

#define JSON_DICT_IMAGE_TRANSFORM_OFFSET_X @"json_dict_channel_transform_offset_x"
#define JSON_DICT_IMAGE_TRANSFORM_OFFSET_Y @"json_dict_channel_transform_offset_y"
#define JSON_DICT_IMAGE_TRANSFORM_ROTATION @"json_dict_channel_transform_rotation"
#define JSON_DICT_IMAGE_TRANSFORM_COMPRESS_X @"json_dict_channel_transform_compress_x"
#define JSON_DICT_IMAGE_TRANSFORM_COMPRESS_Y @"json_dict_channel_transform_compress_y"

#define JSON_DICT_3DS @"json_dict_3ds"
#define JSON_DICT_3DS_COMPONENTS @"json_dict_3ds_comps"
#define JSON_DICT_3DS_COMPUTATIONS @"json_dict_3ds_computations"
#define JSON_DICT_3DS_METADATA @"json_dict_3ds_metadata"
#define JSON_DICT_3DS_METADATA_TYPE @"json_dict_3ds_met_type"
#define JSON_DICT_3DS_METADATA_ORIGIN @"json_dict_3ds_met_origin"
#define JSON_DICT_3DS_METADATA_CHANNEL @"json_dict_3ds_met_chan"
#define JSON_DICT_3DS_METADATA_SUBST_CHANNEL @"json_dict_3ds_met_subchan"
#define JSON_DICT_3DS_METADATA_THRESHOLD @"json_dict_3ds_met_thres"
#define JSON_DICT_3DS_METADATA_STEP_WATERSHED @"json_dict_3ds_met_stepwtshd"
#define JSON_DICT_3DS_METADATA_EXPANSION @"json_dict_3ds_met_exp"
#define JSON_DICT_3DS_METADATA_MIN_KERNEL @"json_dict_3ds_minker"
#define JSON_DICT_3DS_METADATA_WIDTH @"json_dict_3ds_width"
#define JSON_DICT_3DS_METADATA_HEIGHT @"json_dict_3ds_height"
#define JSON_DICT_3DS_METADATA_THICK @"json_dict_3ds_thick"
#define JSON_DICT_3DS_METADATA_SHEEP_SHAVER @"json_dict_3ds_sheep"


//METADATA
#define JSON_METADATA @"json_metadata"
#define JSON_METADATA_KEYS @"json_metadata_keys"
#define JSON_METADATA_VALUES_DICT @"json_metadata_values_dict"


//METRICS
#define JSON_METRICS @"json_metrics"
#define JSON_METRIC_TYPE @"json_metric_type"
#define JSON_METRIC_NAME @"json_metric_name"
#define JSON_METRIC_HASH @"json_metric_hash"
#define JSON_METRIC_CHANNELS @"json_metric_channels"
#define JSON_METRIC_FILTERS @"json_metric_filters"
#define JSON_METRIC_AND_FILTER @"json_metric_and_filter"

//EXTENSIONS

#define EXTENSION_WORKSPACE @"wimc"

#define EXTENSION_BIMC @"bimc"
#define EXTENSION_TIFF @"tiff"
#define EXTENSION_TIF @"tif"
#define EXTENSION_TIFF_PREFIX @"tif"
#define EXTENSION_TXT @"txt"
#define EXTENSION_MCD @"mcd"
#define EXTENSION_MAT @"mat"
#define EXTENSION_JPG @"jpg"
#define EXTENSION_JPEG @"jpeg"
#define EXTENSION_PNG @"png"
#define EXTENSION_BMP @"bmp"
#define EXTENSION_FCS @"fcs"
#define EXTENSION_CDT @"cdti"

//PREFERENCES
#define PREF_LOCATION_DRIVE_CP @"PREF_LOCATION_DRIVE_CP"
#define PREF_LOCATION_DRIVE_ILTK @"PREF_LOCATION_DRIVE_ILTK"
#define PREF_LOCATION_DRIVE_IJ @"PREF_LOCATION_DRIVE_IJ"
#define PREF_LOCATION_DRIVE_R @"PREF_LOCATION_DRIVE_R"
#define TYPICAL_R_LOCATION @"/Library/Frameworks/R.framework"
#define PREF_COLORSPACE @"PREF_COLORSPACE"
#define PREF_USE_METAL @"PREF_USE_METAL"

//SAVING THE 3D-STATE
#define THREE_D_ROI @"3DROI"
#define THREE_D_ZOOM @"3DZOOM"
#define THREE_D_POS @"3DPOS"
#define THREE_D_ROT @"3DROT"

//COMPENSTION MATRIX
#define COMP_MATRIX @"COMP_MATRIX"


//TypeDefs
typedef enum
{
    MASK_ALL_CELL,
    MASK_NUC_PLUS_CYT,
    MASK_NUC,
    MASK_CYT
} MaskType;
typedef enum
{
    MASK_BORDER,
    MASK_FULL,
    MASK_NO_BORDERS,
    MASK_ONE_COLOR_BORDER
} MaskOption;

#endif /* globals_h */
