#!/usr/bin/env python3

import random
import argparse

def random_rgb():
    return random.randint(1, 255), random.randint(1, 255), random.randint(1, 255)

def create_label_file(labels_path, intensities_path, output_path):
    with open(labels_path, 'r') as label_file:
        roi_labels = label_file.read().splitlines()

    with open(intensities_path, 'r') as intensity_file:
        roi_intensities = [int(x) for x in intensity_file.read().splitlines()]

    if len(roi_labels) != len(roi_intensities):
        print("Error: The label and intensity files have a different number of lines.")
    else:
        with open(output_path, 'w') as output_file:
            for i in range(len(roi_labels)):
                r, g, b = random_rgb()
                output_file.write(f"{roi_labels[i]}\n{roi_intensities[i]} {r} {g} {b} 255\n")

        print(f"The {output_path} file has been created.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Create a label text file from ROI names and intensities.')
    parser.add_argument('labels', help='Path to the ROI names file.')
    parser.add_argument('intensities', help='Path to the ROI intensities file.')
    parser.add_argument('output', help='Path to the output label text file.')

    args = parser.parse_args()

    create_label_file(args.labels, args.intensities, args.output)
