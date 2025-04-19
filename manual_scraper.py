# mANUALLY PRINT pdf OF ALL WEB PAGE, MANUALLY CONVERT TO ODG THEN TO html THEN TO XLSX then run following code 

import pandas as pd

# Load the Excel file
xlsx_path = "/mnt/data/Unsere Einsätze – Feuerwehr Freiburg.xlsx"
df_raw = pd.read_excel(xlsx_path, header=None)

# Preview the first few lines to understand the pattern
df_raw.head(20)


# Step 1: Clean the data
# Remove NaN and strip all strings
cleaned = df_raw.dropna()[0].str.strip()

# Remove repeating headers like "Datum", "Einsatz", "Link" and any variants
headers_to_remove = ["Datum", "Einsatz", "Link"]
cleaned = cleaned[~cleaned.str.lower().isin([h.lower() for h in headers_to_remove])]

# Preview cleaned content
cleaned.reset_index(drop=True).head(20)


import re

# Reset index for safe iteration
lines = cleaned.reset_index(drop=True)

# Store results here
entries = []

i = 0
while i < len(lines):
    line = lines[i]

    # Match date pattern like "09.04.2025 15:38"
    if re.match(r"\d{2}\.\d{2}\.\d{4} \d{2}:\d{2}", line):
        datum = line

        # Try to capture one or two lines of Einsatz
        einsatz_lines = []
        j = i + 1
        while j < len(lines):
            next_line = lines[j]
            # Stop if the next line is also a date (start of a new block)
            if re.match(r"\d{2}\.\d{2}\.\d{4} \d{2}:\d{2}", next_line):
                break
            einsatz_lines.append(next_line)
            j += 1

        full_einsatz = " ".join(einsatz_lines).strip()
        if ":" in full_einsatz:
            einsatz, zusammenfassung = [s.strip() for s in full_einsatz.split(":", 1)]
        else:
            einsatz, zusammenfassung = full_einsatz, ""

        entries.append({
            "Datum": datum,
            "Einsatz": einsatz,
            "Zusammenfassung": zusammenfassung
        })

        i = j  # jump to next block
    else:
        i += 1  # skip any unexpected lines

# Create DataFrame
df_result = pd.DataFrame(entries)

# Save to CSV
csv_output_path = "/data/einsaetze_abt07_cleaned.csv"
df_result.to_csv(csv_output_path, index=False, encoding="utf-8")
csv_output_path


# Remove unwanted "Details (https://" and anything that follows from the 'Einsatz' column
df_result["Einsatz"] = df_result["Einsatz"].str.replace(r"Details \(https://.*?$", "", regex=True).str.strip()

# Save updated CSV
cleaned_csv_path = "/data/einsaetze_abt07_cleaned_final.csv"
df_result.to_csv(cleaned_csv_path, index=False, encoding="utf-8")
cleaned_csv_path


# Remove everything from the word "Details" onward in the 'Einsatz' column
df_result["Einsatz"] = df_result["Einsatz"].str.replace(r"Details.*$", "", regex=True).str.strip()

# Save final version
final_csv_path = "/mnt/data/einsaetze_abt07_cleaned_stripped.csv"
df_result.to_csv(final_csv_path, index=False, encoding="utf-8")
final_csv_path


# Reapply the original "Details" removal on the correct DataFrame that includes all columns
df_result["Einsatz"] = df_result["Einsatz"].str.replace(r"Details.*$", "", regex=True).str.strip()

# Save again including the Zusammenfassung column
final_with_zusammenfassung_path = "/mnt/data/einsaetze_abt07_cleaned_stripped_full.csv"
df_result.to_csv(final_with_zusammenfassung_path, index=False, encoding="utf-8")
final_with_zusammenfassung_path
