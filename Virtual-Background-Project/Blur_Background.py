import cv2
import mediapipe as mp
import numpy as np
import matplotlib.pyplot as plt


def modifyBackground(image, background_image = 255, blur = 95, threshold = 0.3, method='changeBackground'):
    RGB_img = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
 
    # Initializing mediapipe segmentation class.
    mp_selfie_segmentation = mp.solutions.selfie_segmentation
    segment = mp_selfie_segmentation.SelfieSegmentation(model_selection=1)

    # Perform the segmentation.
    result = segment.process(RGB_img)
    
    # Get a binary mask having pixel value 1 for the object and 0 for the background.
    # Pixel values greater than the threshold value will become 1 and the remainings will become 0.
    binary_mask = result.segmentation_mask > threshold
    
    # Stack the same mask three times to make it a three channel image.
    binary_mask_3 = np.dstack((binary_mask,binary_mask,binary_mask))
        
    if method == 'blurBackground':
        blurred_image = cv2.GaussianBlur(image, (blur, blur), 0)
        output_image = np.where(binary_mask_3, image, blurred_image)
    
    elif method == 'desatureBackground':
        grayscale = cv2.cvtColor(src = image, code = cv2.COLOR_BGR2GRAY)
        
        grayscale_3 = np.dstack((grayscale,grayscale,grayscale))

        output_image = np.where(binary_mask_3, image, grayscale_3)
    
    return output_image, (binary_mask_3 * 255).astype('uint8')

cap = cv2.VideoCapture(0)

# Setting Width and Height
cap.set(3, 1280)
cap.set(4, 720)


while cap.isOpened():
    ret, frame = cap.read()

    if not ret:
        continue

    # Flip the frame horizontally for natural (selfie-view) visualization.
    frame = cv2.flip(frame, 1)

    output_frame,_ = modifyBackground(frame, threshold = 0.3, method='desatureBackground')

    cv2.imshow('Video', output_frame)

    k = cv2.waitKey(1)
    if k == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()