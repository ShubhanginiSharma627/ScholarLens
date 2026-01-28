import json
import chromadb
from chromadb.utils import embedding_functions
import os

DATA_FILE = "data/cleaned_exam.json"
DB_PATH = "vector_store" 

def build_knowledge_base():
    print("Building Vector Database...")

    if not os.path.exists(DATA_FILE):
        print(f"Error: {DATA_FILE} not found. Did you run script 1?")
        return

    with open(DATA_FILE, 'r') as f:
        data = json.load(f)

    client = chromadb.PersistentClient(path=DB_PATH)
    
    try:
        client.delete_collection(name="exam_knowledge")
    except:
        pass


    ef = embedding_functions.SentenceTransformerEmbeddingFunction(model_name="all-MiniLM-L6-v2")

    collection = client.create_collection(name="exam_knowledge", embedding_function=ef)
 
    ids = []
    documents = [] 
    metadatas = [] 

    print(f"Processing {len(data)} items...")

    for item in data:
        combined_text = f"Question: {item.get('prompt', '')} Context: {item.get('lecture', '')}"
        
        ids.append(str(item['id']))
        documents.append(combined_text) 
        metadatas.append({
            "subject": str(item.get('subject') or "General"),
            "topic": str(item.get('topic') or "General"),
            "solution": str(item.get('solution') or "") 
        })


    batch_size = 500
    total_batches = len(ids) // batch_size + 1
    
    for i in range(0, len(ids), batch_size):

        batch_ids = ids[i:i+batch_size]
        batch_docs = documents[i:i+batch_size]
        batch_meta = metadatas[i:i+batch_size]
        
        if batch_ids:
            collection.add(
                ids=batch_ids,
                documents=batch_docs,
                metadatas=batch_meta
            )
            print(f"   Added batch {i//batch_size + 1}/{total_batches}...")

    print("Database built successfully in /vector_store!")

if __name__ == "__main__":
    build_knowledge_base()