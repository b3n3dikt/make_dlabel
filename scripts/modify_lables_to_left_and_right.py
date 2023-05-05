import argparse
import os


def modify_labels(input_file, output_dir, output_suffix, prefix):
    with open(input_file, 'r') as f:
        lines = f.readlines()

    modified_lines = [prefix + line for line in lines]

    output_file_name = os.path.splitext(os.path.basename(input_file))[0] + output_suffix + '.txt'
    output_file_path = os.path.join(output_dir, output_file_name)

    with open(output_file_path, 'w') as f:
        f.writelines(modified_lines)


def main():
    parser = argparse.ArgumentParser(description='Modify labels and save to the specified output directory.')
    parser.add_argument('input_file', help='Input text file containing the labels.')
    parser.add_argument('--output_dir', help='Output directory for the left and right hemisphere labels.', default=None)

    args = parser.parse_args()

    if args.output_dir is None:
        args.output_dir = os.path.dirname(args.input_file)

    modify_labels(args.input_file, args.output_dir, '_LeftHem', 'L_')
    modify_labels(args.input_file, args.output_dir, '_RightHem', 'R_')


if __name__ == '__main__':
    main()
