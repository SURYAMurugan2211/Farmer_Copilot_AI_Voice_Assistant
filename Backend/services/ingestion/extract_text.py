import os

def extract_text_from_file(file_path: str) -> str:
    """
    Extract text from various file formats
    Supports: PDF, TXT, DOCX files
    """
    file_ext = os.path.splitext(file_path)[1].lower()
    
    if file_ext == ".txt":
        with open(file_path, "r", encoding="utf-8") as f:
            return f.read()
    
    elif file_ext == ".pdf":
        try:
            import PyPDF2
            with open(file_path, "rb") as f:
                reader = PyPDF2.PdfReader(f)
                text = ""
                for page in reader.pages:
                    text += page.extract_text() + "\n"
                return text
        except ImportError:
            raise Exception("PyPDF2 not installed. Install with: pip install PyPDF2")
    
    elif file_ext in [".docx", ".doc"]:
        try:
            from docx import Document
            doc = Document(file_path)
            text = ""
            for paragraph in doc.paragraphs:
                text += paragraph.text + "\n"
            return text
        except ImportError:
            raise Exception("python-docx not installed. Install with: pip install python-docx")
    
    else:
        raise Exception(f"Unsupported file format: {file_ext}")