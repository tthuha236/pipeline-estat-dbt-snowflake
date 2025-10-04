# Use the official Python image
FROM python:3.11-slim

# Set the working directory
WORKDIR /app

# Copy all files
COPY . .

# Install dependencies
RUN pip install --no-cache-dir streamlit

# Add other dependencies here
RUN pip install -r requirements.txt

# Expose Streamlit default port
EXPOSE 8501

# Streamlit needs this environment variable in some setups
ENV PYTHONUNBUFFERED=1

# Command to run the Streamlit app
CMD ["streamlit", "run", "app.py", "--server.port=8501", "--server.enableCORS=false"]