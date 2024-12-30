import os
import chardet
import pandas as pd

def detect_encoding(file_path):
    """Detect the encoding of a file using chardet."""
    with open(file_path, 'rb') as f:
        raw_data = f.read()  # Read the entire file for better accuracy
    result = chardet.detect(raw_data)
    return result['encoding']

def clean_special_characters(df):
    """Replace or remove special characters in the DataFrame."""
    return df.applymap(lambda x: x.encode('ascii', 'ignore').decode('utf-8') if isinstance(x, str) else x)

def convert_to_utf8(input_dir, output_dir):
    """Convert all CSV files in the input directory to UTF-8 encoding."""
    # Ensure output directory exists
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)

    # Process all files in the directory
    for file_name in os.listdir(input_dir):
        if file_name.endswith('.csv'):  # Only process CSV files
            input_file_path = os.path.join(input_dir, file_name)
            output_file_path = os.path.join(output_dir, file_name)

            print(f"Processing file: {file_name}")

            try:
                # Detect encoding
                encoding = detect_encoding(input_file_path)
                print(f"Detected encoding for {file_name}: {encoding}")

                # Use fallback encoding if ASCII is detected
                if encoding == 'ascii':
                    print(f"ASCII detected for {file_name}. Using 'latin1' as fallback.")
                    encoding = 'latin1'

                # Read the file
                df = pd.read_csv(input_file_path, encoding=encoding)

                # Clean special characters (optional)
                df = clean_special_characters(df)

                # Save the file as UTF-8
                df.to_csv(output_file_path, index=False, encoding='utf-8')
                print(f"Successfully converted {file_name} to UTF-8.")

            except Exception as e:
                print(f"Error processing {file_name}: {e}")

if __name__ == "__main__":
    # Directory containing your dataset files
    input_directory = '/Users/jcrispii/Downloads/SQL Projects/GlobalElectronicsRetailer/original_data'
    output_directory = '/Users/jcrispii/Downloads/SQL Projects/GlobalElectronicsRetailer/data-utf8'

    # Convert all files
    convert_to_utf8(input_directory, output_directory)


