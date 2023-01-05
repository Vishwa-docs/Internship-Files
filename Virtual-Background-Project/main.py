import cv2
import mediapipe as mp
import numpy as np
from PIL import Image

mp_drawing = mp.solutions.drawing_utils # What is this for
mp_selfie_segmentation = mp.solutions.selfie_segmentation


BG_COLOR = (192, 192, 192) # gray
MASK_COLOR = (255, 255, 255) # white


# Functions for generating Gradient Background
def generate_gradient_image(width, height, colors):
    # Create an image with a linear gradient from the colors
    image = np.zeros((height, width, 3), dtype=np.uint8)
    colors = [np.array(color, dtype=np.uint8) for color in colors]
    num_colors = len(colors)
    for y in range(height):
        fraction = y / height
        color_index = int(fraction * (num_colors - 1))
        color = (1.0 - fraction) * colors[color_index] + fraction * colors[color_index + 1]
        color = color.astype(np.uint8)
        image[y] = color
    # Convert the image to a PIL image and return it
    return Image.fromarray(image)


# Read the Background image for Virtual Background
background_image = cv2.imread('Image.jpeg') 

cap = cv2.VideoCapture(0) # Capture the webcam feed


with mp_selfie_segmentation.SelfieSegmentation(model_selection=1) as selfie_segmentation: # model_selection = 1 is for landscape model
    bg_image = None

    while cap.isOpened():
        success, image = cap.read()
        if not success:
            print("Ignoring empty camera frame.")
            continue

        # Flip the image horizontally for a later selfie-view display, and convert the BGR image to RGB.
        image = cv2.cvtColor(cv2.flip(image, 1), cv2.COLOR_BGR2RGB)
        # To improve performance, optionally mark the image as not writeable to pass by reference.
        image.flags.writeable = False

        # Perform selfie segmentation on the RGB image
        results = selfie_segmentation.process(image)

        # Reset the Values
        image.flags.writeable = True
        image = cv2.cvtColor(image, cv2.COLOR_RGB2BGR)

        # Draw the segmentation on the image
        condition = np.stack((results.segmentation_mask,) * 3, axis=-1) > 0.1

        if bg_image is None:
            # # Grey Background
            # bg_image = np.zeros(image.shape, dtype=np.uint8)
            # bg_image[:] = BG_COLOR
            

            
            # # Gradient Colour
            bg_image = generate_gradient_image(1280, 720, [(240, 247, 212), (178, 215, 50), (102, 176, 50)])
            
            
            # Image Background
            # bg_image = cv2.resize(background_image, (1280,720), interpolation = cv2.INTER_LINEAR)
            # blurred_image = cv2.GaussianBlur(bg_image, (95, 95), 0)
            # INTER_LINEAR : A bilinear interpolation over 2x2 pixel neighborhood
            # interpolation : way the extra pixels in the new image is calculated


        output_image = np.where(condition, image, bg_image)
        # Joint Bilateral Filter
        # image = cv2.ximgproc.jointBilateralFilter(image, np.uint8(results.segmentation_mask), 9, sigmaColor=75, sigmaSpace=75)
        # image = cv2.bilateralFilter(image, 10, sigmaColor=10, sigmaSpace=10)

        # pipeline = mp.pipeline(config='selfie_segmentation_mobile_gpu.pbtxt')
        # pipeline.add_calculator(mp.JointBilateralFilterCalculator())

        # pipeline.start(input_image)
        # output_image = pipeline.get_output()

        cv2.imshow('MediaPipe Selfie Segmentation', output_image)
        if cv2.waitKey(5) & 0xFF == 'q':
            break

cap.release()
cv2.destroyAllWindows()
