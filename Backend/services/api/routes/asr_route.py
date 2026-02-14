from fastapi import APIRouter, UploadFile, File
import uuid
import os
import aiofiles
from services.asr.asr_service import transcribe

router = APIRouter()

TMP = "Farmer_copilot/Backend/storage/temp"
os.makedirs(TMP, exist_ok=True)

@router.post("/")
async def asr(file: UploadFile = File(...)):
    file_path = f"{TMP}/{uuid.uuid4().hex}.wav"
    async with aiofiles.open(file_path, "wb") as f:
        data = await file.read()
        await f.write(data)
    return transcribe(file_path)
