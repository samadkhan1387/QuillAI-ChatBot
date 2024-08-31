Developed by : Abdul Samad
## Architecture

he architecture of the Quill Ai app is designed to efficiently process and interact with PDF documents, along with a voice chat feature for enhanced user interaction. Here's a breakdown of the workflow:

### Overview

The "Chat with PDF" feature of the Quill Ai app allows users to interact with the content of a PDF document in a conversational manner. Additionally, users can send voice messages that are transcribed into text, and they can listen to responses in voice form. The app extracts information from the PDF, processes it, and provides relevant responses to user queries.

### Workflow Steps

1. PDF Extraction: The PDF document is processed to extract its pages.

2. Chunking: The extracted pages are then split into manageable chunks for processing.

3. Batching: Chunks are grouped into batches (e.g., 1 batch = 100 chunks) for parallel processing.

4. Embedding Generation: Each batch is sent to an Embeddings API with the task type set to 'Document'. The API generates a list of vector embeddings for each chunk.

5. Local Storage: The generated embeddings for each batch are split into individual chunk embeddings. These embeddings are stored locally using Hive (a key-value database).

6. User Interaction: Users can input instructions either as text or through voice chat. Voice messages are converted to text, and the app sends the query to the Embeddings API with the task type set to 'Query' to generate an embedding for the query.

7. Semantic Search: The app performs a semantic search by taking the embedding of the user's query and comparing it across the document embeddings stored in Hive.

8. Ranking Results: The chunks are ranked based on the Euclidean distance between the query embedding and document embeddings. The top-ranked chunks are used as the context for the language model (LLM).

9. Response Generation: The language model generates an answer based on the context provided by the top-ranked chunks. The response is delivered as text, and users can choose to listen to the response in voice form.

### Technologies Used

- **Flutter**: For cross-platform mobile application development.
- **Hive**: For local storage of chunk embeddings.
- **Gemini Embeddings API**: For generating vector embeddings of text.
- **Gemini (LLM)**: For generating responses based on context.
- **Riverpod**: For managing states across the app.
- **Voice Chat Integration**: For converting voice messages to text and playing responses in voice.

### Prerequisites

If you need Need the latest Gemini api key from [here](https://makersuite.google.com/app/apikey)