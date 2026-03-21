FROM mcr.microsoft.com/playwright/python:v1.40.0-jammy

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
# the folowing line copy the hole repository (including ublock and adguard)
COPY . . 

# Installation of playrigth chromium
RUN playwright install chromium
