import argparse
import os


def modify_intensities(input_file, output_dir, value_to_add):
    with open(input_file, 'r') as f:
        lines = f.readlines()

    modified_lines = [str(int(line.strip()) + value_to_add) + '\n' for line in lines]

    output_file_name = os.path.splitext(os.path.basename(input_file))[0] + '_modified.txt'
    output_file_path = os.path.join(output_dir, output_file_name)

    with open(output_file_path, 'w') as f:
        f.writelines(modified_lines)


def main():
    parser = argparse.ArgumentParser(description='Modify intensity values and save to the specified output directory.')
    parser.add_argument('input_file', help='Input text file containing the intensity values.')
    parser.add_argument('value_to_add', type=int, help='Value to add to each intensity value.')
    parser.add_argument('--output_dir', help='Output directory for the modified intensity values.', default=None)

    args = parser.parse_args()

    if args.output_dir is None:
        args.output_dir = os.path.dirname(args.input_file)

    modify_intensities(args.input_file, args.output_dir, args.value_to_add)


if __name__ == '__main__':
    main()
