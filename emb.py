import os
import sys
from sentence_transformers import SentenceTransformer, util

def extract_text_from_file(file_path):
    """Extract all text contents of the file."""
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as file:
        return file.read()

def create_embedding(text, model):
    """Generate text embedding using the specified model."""
    return model.encode(text, convert_to_tensor=True)

def main():
    # Check the command line parameters to make sure that at least three parameters are passed in:
    # 1. error_message (Error message string, obtained by extract_error_info())
    # 2. testbench_file (the latest generated testbench file, such as kernel_testbench0_c{iteration}.cpp)
    # 3. library_dir (the directory where the template library is located)
    if len(sys.argv) < 4:
        print("Usage: python3 emb.py <error_message> <testbench_file> <library_dir>")
        sys.exit(1)
    
    # Get parameters from the command line
    error_message = sys.argv[1]
    testbench_file = sys.argv[2]
    library_dir = sys.argv[3]
    
    # Use error_message as target error text
    text1_content = error_message
    
    # Read the latest testbench file content
    if os.path.exists(testbench_file):
        testbench_content = extract_text_from_file(testbench_file)
    else:
        print(f"Testbench file not found: {testbench_file}")
        sys.exit(1)
    
    # Merge error message with testbench file content
    combined_text = text1_content + "\n" + testbench_content
    
    # Loading a pretrained SentenceTransformer model
    model = SentenceTransformer('all-MiniLM-L6-v2')
    target_embedding = create_embedding(combined_text, model)
    
    # Iterate through all txt files in library_dir and calculate the cosine similarity between each file and the target text
    results = []
    for root, dirs, files in os.walk(library_dir):
        for file in files:
            if file.endswith('.txt'):
                file_path = os.path.join(root, file)
                file_text = extract_text_from_file(file_path)
                file_embedding = create_embedding(file_text, model)
                similarity = util.pytorch_cos_sim(target_embedding, file_embedding)
                # Save (similarity, file name)
                results.append((similarity.item(), file))
    
    if not results:
        print("No txt file was found in the specified library_dir.")
        sys.exit(1)
    
    # Sort in descending order of similarity and select the template file with the highest similarity
    results.sort(key=lambda x: x[0], reverse=True)
    best_similarity, best_file = results[0]
    
    # Output in expected format: template file name, similarity
    print(f"{best_file}, {best_similarity}")

if __name__ == "__main__":
    main()
