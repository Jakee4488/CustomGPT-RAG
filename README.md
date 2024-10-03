Here is a draft for your README file based on the gathered code and structure of the `Jakee4488/CustomGPT-RAG` repository:

# CustomGPT-RAG

Chat Bot using LLM models and custom fine-tuning with RAG.

## Table of Contents
- [Introduction](#introduction)
- [Installation](#installation)
- [Usage](#usage)
- [Code Overview](#code-overview)
- [Local GPT UI](#local-gpt-ui)
- [Ingesting Documents](#ingesting-documents)
- [Running Locally](#running-locally)
- [API Integration](#api-integration)
- [Contributing](#contributing)
- [License](#license)

## Introduction
CustomGPT-RAG is a chatbot project that leverages large language models (LLM) and Retrieval-Augmented Generation (RAG) to provide enhanced interactive responses. This project allows for custom fine-tuning and operates even without an internet connection, making it ideal for handling sensitive data.

## Installation
To get started with CustomGPT-RAG, follow these steps:

1. Clone the repository:
    ```bash
    git clone https://github.com/Jakee4488/CustomGPT-RAG.git
    cd CustomGPT-RAG
    ```

2. Install the necessary dependencies:
    ```bash
    pip install -r requirements.txt
    ```

## Usage
### Running the UI
To run the UI locally, use the following command:
```bash
python localGPTUI/localGPTUI.py --host 0.0.0.0 --port 5111
```
This will start the UI on `localhost:5111`.

### Ingesting Documents
To ingest documents into the system, use the UI to upload the files. Supported formats include text, PDF, CSV, and Excel files. The application processes these documents to create a comprehensive database for the model.

## Code Overview
### Main Components
- **localGPTUI/localGPTUI.py**: Defines the Flask application to render the UI and handle user inputs.
- **ingest.py**: Handles the ingestion of documents, splitting them into chunks, and creating embeddings.
- **run_localGPT.py**: Implements the main logic for the local GPT, including setting up the QA system and running the interactive loop.
- **run_localGPT_API.py**: Provides API endpoints to manage document ingestion and prompt handling.

### Detailed Explanation
#### localGPTUI/localGPTUI.py
- Manages the web interface using Flask.
- Handles user prompts and document uploads.
- Interacts with backend endpoints to process user inputs.

#### ingest.py
- Loads documents from a specified source directory.
- Splits documents into manageable chunks.
- Creates embeddings using specified models and stores them in a vectorstore.

#### run_localGPT.py
- Sets up the local QA system with specified device type and options.
- Runs an interactive loop for user queries and returns answers based on ingested documents.

#### run_localGPT_API.py
- Defines API endpoints to delete and save documents, run ingestion, and handle user prompts.
- Executes ingestion scripts and manages the document database.

## Local GPT UI
The UI is built using Flask and renders templates defined in `localGPTUI/templates/home.html`. The main functionalities include:
- Uploading and managing documents.
- Submitting user prompts and displaying responses.

## Ingesting Documents
Documents can be ingested by uploading them through the UI. The backend processes these files, creating embeddings and storing them for efficient retrieval during QA sessions.

## Running Locally
To run the application locally, follow the usage instructions to start the UI and handle document ingestion. Ensure that all dependencies are installed and the necessary directories are set up.

## API Integration
The project provides several API endpoints to manage documents and handle user prompts:
- `/api/delete_source`: Deletes and recreates the source document folder.
- `/api/save_document`: Saves uploaded documents to the server.
- `/api/run_ingest`: Runs the document ingestion process.
- `/api/prompt_route`: Handles user prompts and returns responses.

## Contributing
Contributions are welcome! Please fork the repository and submit a pull request with your changes. Ensure your code adheres to the project's coding standards and includes appropriate tests.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for more details.

---

Feel free to further customize this README to suit your project's needs. Let me know if you need any additional information or modifications!
