# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "click",
#     "google-cloud-documentai",
#     "google-cloud-documentai-toolbox",
#     "ocrmypdf",
#     "pikepdf",
# ]
# ///

import os
import tempfile
from io import BytesIO
from pathlib import Path
from typing import Optional

import click


def process_pdf(
    input_file: str,
    output_file: str,
    project_id: str,
    location: str,
    processor_id: str,
    processor_version: str,
):
    """
    Process a PDF file, adding an OCR layer using Google Document AI.

    Args:
        input_file (str): Path to the input PDF file.
        output_file (str): Path where the processed PDF will be saved.
        project_id (str): The Google Cloud project ID.
        location (str): The location of the Document AI processor.
        processor_id (str): The ID of the Document AI processor.
        processor_version (str): The version of the Document AI processor.
    """
    from google.api_core.client_options import ClientOptions
    from google.cloud import documentai
    from google.cloud.documentai_toolbox import document as dai_document
    from ocrmypdf.hocrtransform import HocrTransform
    from pikepdf import Page, Pdf, PdfImage

    client = documentai.DocumentProcessorServiceClient(
        client_options=ClientOptions(
            api_endpoint=f"{location}-documentai.googleapis.com"
        )
    )

    name = client.processor_version_path(
        project_id, location, processor_id, processor_version
    )

    with Pdf.open(input_file) as pdf_document:
        combined_pdf = Pdf.new()
        total_pages = len(pdf_document.pages)

        with click.progressbar(
            pdf_document.pages, label="Processing pages", length=total_pages
        ) as pages:
            for page_num, page in enumerate(pages):
                if len(page.images) != 1:
                    click.echo(
                        f"Error: Page {page_num + 1} has {len(page.images)} images. Expected exactly 1 image per page."
                    )
                    raise click.Abort()

                for _, raw_image in page.images.items():
                    pdfimage = PdfImage(raw_image)
                    image = pdfimage.as_pil_image()

                    # Calculate DPI
                    pdf_page = Page(page)
                    page_width = float(pdf_page.mediabox[2]) - float(
                        pdf_page.mediabox[0]
                    )
                    page_height = float(pdf_page.mediabox[3]) - float(
                        pdf_page.mediabox[1]
                    )
                    image_width, image_height = image.size
                    dpi_x = round(image_width / (page_width / 72))
                    dpi_y = round(image_height / (page_height / 72))
                    dpi = max(dpi_x, dpi_y)  # Use the higher DPI
                    click.echo(f"DPI: {dpi}")

                    # Save the image to a BytesIO object
                    image_buffer = BytesIO()
                    image.save(image_buffer, format="PNG")
                    image_buffer.seek(0)

                    process_options = documentai.ProcessOptions(
                        ocr_config=documentai.OcrConfig(
                            enable_native_pdf_parsing=False,
                            enable_image_quality_scores=False,
                            enable_symbol=False,
                            premium_features=documentai.OcrConfig.PremiumFeatures(
                                compute_style_info=False,
                                enable_math_ocr=False,
                                enable_selection_mark_detection=False,
                            ),
                        )
                    )

                    # Process the document
                    image_content = image_buffer.getvalue()
                    request = documentai.ProcessRequest(
                        name=name,
                        raw_document=documentai.RawDocument(
                            content=image_content, mime_type="image/png"
                        ),
                        process_options=process_options,
                    )
                    result = client.process_document(request=request)
                    document = result.document

                    # Convert Document to hOCR format
                    wrapped_document = dai_document.Document.from_documentai_document(
                        document
                    )
                    hocr_content = wrapped_document.export_hocr_str(
                        title=f"Page {page_num+1}"
                    )

                    # Use temporary files for hOCR content and image
                    with tempfile.NamedTemporaryFile(
                        mode="w", suffix=".hocr", delete=False
                    ) as hocr_file, tempfile.NamedTemporaryFile(
                        mode="wb", suffix=".png", delete=False
                    ) as img_file, tempfile.NamedTemporaryFile(
                        mode="wb", suffix=".pdf", delete=False
                    ) as temp_output:
                        # Write hOCR content
                        hocr_file.write(hocr_content)
                        hocr_file.flush()

                        # Write image
                        img_file.write(image_buffer.getvalue())
                        img_file.flush()

                        # Use HocrTransform to create a new PDF with the OCR layer
                        hocr_transform = HocrTransform(
                            hocr_filename=hocr_file.name,
                            dpi=dpi,  # Use the calculated DPI
                        )

                        hocr_transform.to_pdf(
                            out_filename=Path(temp_output.name),
                            image_filename=Path(img_file.name),
                            invisible_text=True,
                        )

                        # Add the page to the combined PDF
                        temp_pdf = Pdf.open(temp_output.name)
                        combined_pdf.pages.extend(temp_pdf.pages)

                    # We only process the first image of each page
                    break

        combined_pdf.save(output_file)


def copy_binary_file(source_path, destination_path):
    """Just copies the file content, avoids chmod/stat calls like shutil does."""
    # Open the source file in binary read mode
    with open(source_path, "rb") as source_file:
        # Open the destination file in binary write mode
        with open(destination_path, "wb") as destination_file:
            # Read the source file in chunks and write to the destination file
            chunk_size = 4096  # You can adjust this value based on your needs
            while True:
                chunk = source_file.read(chunk_size)
                if not chunk:
                    break
                destination_file.write(chunk)


@click.command()
@click.argument("input_file", type=click.Path(exists=True))
@click.option(
    "--output-file",
    type=click.Path(),
    help="Optional output file path. If not provided, the input file will be updated in place.",
)
@click.option("--project-id", help="Google Cloud project ID")
@click.option("--location", help="Google Cloud location (e.g., 'us' or 'eu')")
@click.option("--processor-id", help="Document AI processor ID")
@click.option("--processor-version", help="Document AI processor version")
def main(
    input_file: str,
    output_file: Optional[str],
    project_id: str,
    location: str,
    processor_id: str,
    processor_version: str,
):
    """
    Process a PDF file using Google Document AI and add an OCR layer.

    Args:
        input_file (str): Path to the input PDF file.
        output_file (Optional[str]): Path where the processed PDF will be saved. If None, update input file in place.
        project_id (str): The Google Cloud project ID.
        location (str): The location of the Document AI processor.
        processor_id (str): The ID of the Document AI processor.
        processor_version (str): The version of the Document AI processor.
    """
    # Check environment variables for optional parameters
    if not project_id:
        project_id = os.environ.get("GOOGLE_OCR_PROJECT_ID", "")
    if not location:
        location = os.environ.get("GOOGLE_OCR_LOCATION", "eu")
    if not processor_id:
        processor_id = os.environ.get("GOOGLE_OCR_PROCESSOR_ID", "")
    if not processor_version:
        processor_version = os.environ.get("GOOGLE_OCR_PROCESSOR_VERSION", "rc")

    # Validate required parameters
    if not project_id:
        raise click.UsageError(
            "Project ID is required. Provide it as an argument or set GOOGLE_OCR_PROJECT_ID environment variable."
        )
    if not processor_id:
        raise click.UsageError(
            "Processor ID is required. Provide it as an argument or set GOOGLE_OCR_PROCESSOR_ID environment variable."
        )

    click.echo(f"Processing {input_file}...")
    with tempfile.NamedTemporaryFile(suffix=".pdf") as temp_output:
        process_pdf(
            input_file,
            temp_output.name,
            project_id,
            location,
            processor_id,
            processor_version,
        )

        if output_file:
            copy_binary_file(temp_output.name, output_file)
            click.echo(f"OCR layer added. Output saved to {output_file}")
        else:
            copy_binary_file(temp_output.name, input_file)
            click.echo(f"OCR layer added. Input file {input_file} updated in place.")


if __name__ == "__main__":
    main()
