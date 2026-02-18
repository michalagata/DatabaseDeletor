import json
import os

WORKFLOWS_FILE = '.memory/workflows.json'
PROMPTS_DIR = '.github/prompts'

def main():
    if not os.path.exists(WORKFLOWS_FILE):
        return
    
    if not os.path.exists(PROMPTS_DIR):
        os.makedirs(PROMPTS_DIR)

    try:
        with open(WORKFLOWS_FILE, 'r') as f:
            data = json.load(f)
            
        # Simplistic generator: Key becomes filename, Value becomes content
        # Expand this logic to parse complex workflow objects if needed
        for key, content in data.items():
            filename = f"{key}.prompt.md"
            with open(os.path.join(PROMPTS_DIR, filename), 'w') as out:
                out.write(str(content))
                
        print("Prompts generated successfully.")
    except Exception as e:
        print(f"Error generating prompts: {e}")

if __name__ == "__main__":
    main()
