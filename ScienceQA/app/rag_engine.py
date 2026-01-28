import chromadb

client = chromadb.PersistentClient(path="vector_store")
collection = client.get_collection(name="exam_knowledge")

def search_knowledge(query: str, n_results=2):
    """
    Takes a user question, searches the DB, returns the best 'Lecture' text.
    """
    results = collection.query(
        query_texts=[query],
        n_results=n_results
    )


    if not results['documents'][0]:
        return "No relevant textbook info found."
    

    best_context = " ".join(results['documents'][0])
    topic = results['metadatas'][0][0].get('topic', 'General')
    
    return best_context, topic