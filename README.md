# Snowflake Codes Repository

[![Snowflake](https://img.shields.io/badge/Snowflake-SQL-29B5E8?logo=snowflake)](https://www.snowflake.com/)
[![Status](https://img.shields.io/badge/Status-Active-success)](#)
[![License](https://img.shields.io/badge/License-MIT-blue)](#)

This repository contains SQL scripts and documentation for Snowflake data transformation projects.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [RESPONSE_FLATTEN Script](#response_flatten-script)
  - [Purpose](#purpose)
  - [Requirements](#requirements)
  - [Block-by-Block Explanation](#block-by-block-explanation)
  - [Transformations Applied](#transformations-applied)
  - [Usage Instructions](#usage-instructions)
  - [Verification](#verification)
- [Contributing](#contributing)
- [License](#license)

---

## 🎯 Overview

This repository contains production-ready SQL scripts for Snowflake data warehouse operations, including:
- JSON data flattening
- Data transformations
- ETL processes
- Data quality validations

---

## 📁 Repository Structure

```
Snowflake-codes/
│
├── RESPONSE_FLATTEN.sql    # Main script for flattening JSON response data
└── README.md              # This documentation file
```

---

## 📄 RESPONSE_FLATTEN Script

### Purpose

The `RESPONSE_FLATTEN.sql` script transforms JSON data from the `RESPONSE` table into a normalized, flattened table structure. This script is associated with **Jira Ticket SCRUM-9**.

**Source Table:** `SNOWFLAKE_LEARNING_DB.PUBLIC.RESPONSE`  
**Target Table:** `SNOWFLAKE_LEARNING_DB.PUBLIC.RESPONSE_FLATTEN`  
**Total Columns:** 34 flattened columns

---

### Requirements

The script fulfills the following business requirements:

1. ✅ **Flatten JSON Structure**: Extract all nested JSON fields into individual table columns
2. ✅ **Date Format Transformation**: Convert `lastResponseDate` from ISO 8601 format to `MM/DD/YYYY` format
3. ✅ **String Truncation**: Limit `workplaceEidValidated` column to maximum 3 characters

---

### Block-by-Block Explanation

#### **Block 1: Table Creation**

```sql
CREATE TABLE IF NOT EXISTS SNOWFLAKE_LEARNING_DB.PUBLIC.RESPONSE_FLATTEN (
    activityEidSource VARCHAR,
    activityEidValidated VARCHAR,
    ...
    workplaceEidValidated VARCHAR(3)
);
```

**Purpose:**  
Creates the target table structure with 34 columns to hold the flattened data.

**Key Points:**
- Uses `IF NOT EXISTS` to prevent errors if table already exists
- All columns are `VARCHAR` type to handle text data flexibly
- `workplaceEidValidated` is specifically set to `VARCHAR(3)` to enforce the 3-character constraint
- Creates an empty table ready for data insertion

**Why This Approach?**  
Defining the schema upfront ensures data type consistency and enables the database to enforce constraints at the column level.

---

#### **Block 2: JSON Parsing & Field Extraction**

```sql
INSERT INTO SNOWFLAKE_LEARNING_DB.PUBLIC.RESPONSE_FLATTEN
SELECT 
    PARSE_JSON(JSON):activityEidSource::STRING AS activityEidSource,
    PARSE_JSON(JSON):activityEidValidated::STRING AS activityEidValidated,
    ...
FROM SNOWFLAKE_LEARNING_DB.PUBLIC.RESPONSE;
```

**Purpose:**  
Extracts individual fields from the JSON column and inserts them into the flattened table.

**Key Functions Used:**
- `PARSE_JSON(JSON)`: Parses the JSON string into a semi-structured object
- `:fieldName`: Accesses a specific field within the JSON object using dot notation
- `::STRING`: Casts the extracted value to STRING data type

**Example Transformation:**
```json
// Source JSON
{
  "activityEidSource": null,
  "activityEidValidated": "WBR123",
  ...
}

// Becomes individual columns:
activityEidSource    | activityEidValidated
---------------------|---------------------
NULL                 | WBR123
```

---

#### **Block 3: Date Format Transformation**

```sql
TO_CHAR(TO_TIMESTAMP(PARSE_JSON(JSON):lastResponseDate::STRING), 'MM/DD/YYYY') AS lastResponseDate
```

**Purpose:**  
Converts the `lastResponseDate` field from ISO 8601 format to `MM/DD/YYYY` format.

**Transformation Pipeline:**
1. `PARSE_JSON(JSON):lastResponseDate::STRING` → Extracts the date string from JSON
2. `TO_TIMESTAMP(...)` → Converts the ISO 8601 string to a timestamp object
3. `TO_CHAR(..., 'MM/DD/YYYY')` → Formats the timestamp as a string in MM/DD/YYYY format

**Example:**
```
Input:  "2025-10-07T13:37:28Z"
Output: "10/07/2025"
```

**Why This Format?**  
The MM/DD/YYYY format is commonly used in business reporting and is more human-readable for US-based stakeholders.

---

#### **Block 4: String Truncation**

```sql
LEFT(PARSE_JSON(JSON):workplaceEidValidated::STRING, 3) AS workplaceEidValidated
```

**Purpose:**  
Truncates the `workplaceEidValidated` field to exactly 3 characters.

**Function Used:**
- `LEFT(string, n)`: Returns the leftmost `n` characters from the string

**Example:**
```
Input:  "WBR123"
Output: "WBR"

Input:  "US"
Output: "US" (no change if already ≤3 chars)
```

**Business Rationale:**  
This standardizes workplace identifiers to their 3-character country/region code prefix, removing unnecessary numeric suffixes.

---

#### **Block 5: Trace Fields (Audit Trail)**

```sql
PARSE_JSON(JSON):trace1ClientRequestDate::STRING AS trace1ClientRequestDate,
PARSE_JSON(JSON):trace2CegedimOkcProcessDate::STRING AS trace2CegedimOkcProcessDate,
...
```

**Purpose:**  
Extracts timestamp fields that track the request lifecycle through various systems.

**Trace Field Meaning:**
- `trace1ClientRequestDate`: When the client initiated the request
- `trace2CegedimOkcProcessDate`: When Cegedim OKC processed the request
- `trace3CegedimOkeTransferDate`: When data was transferred to OKE
- `trace4CegedimOkeIntegrationDate`: When data was integrated in OKE
- `trace5CegedimDboResponseDate`: When DBO system responded
- `trace6CegedimOkcExportDate`: When data was exported from OKC

**Use Case:**  
These fields enable performance monitoring and SLA tracking across the entire request processing pipeline.

---

#### **Block 6: Verification Queries**

```sql
-- Verify date format transformation
SELECT 
    lastResponseDate,
    LENGTH(lastResponseDate) AS date_length,
    CASE 
        WHEN lastResponseDate REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN 'Valid Format'
        ELSE 'Invalid Format'
    END AS format_check
FROM SNOWFLAKE_LEARNING_DB.PUBLIC.RESPONSE_FLATTEN;
```

**Purpose:**  
Validates that the transformations were applied correctly.

**Validation Checks:**

1. **Date Format Validation:**
   - Uses `REGEXP` to match pattern `^[0-9]{2}/[0-9]{2}/[0-9]{4}$`
   - Pattern breakdown:
     - `^` = start of string
     - `[0-9]{2}` = exactly 2 digits (month)
     - `/` = literal forward slash
     - `[0-9]{2}` = exactly 2 digits (day)
     - `/` = literal forward slash
     - `[0-9]{4}` = exactly 4 digits (year)
     - `$` = end of string

2. **Length Validation:**
   - Checks that `workplaceEidValidated` is ≤3 characters
   - Verifies the `LEFT()` function worked correctly

3. **Record Count:**
   - Confirms all records were migrated successfully

---

### Transformations Applied

| Field | Transformation | Example |
|-------|----------------|----------|
| `lastResponseDate` | ISO 8601 → MM/DD/YYYY | `2025-10-07T13:37:28Z` → `10/07/2025` |
| `workplaceEidValidated` | Truncate to 3 chars | `WBR123` → `WBR` |
| All other JSON fields | Extract as-is | Direct extraction to columns |

---

### Usage Instructions

#### **Prerequisites**
- Access to Snowflake database `SNOWFLAKE_LEARNING_DB`
- Read access to `PUBLIC.RESPONSE` table
- Write access to `PUBLIC` schema
- Sufficient warehouse compute resources

#### **Execution Steps**

1. **Review Source Data:**
   ```sql
   SELECT JSON FROM SNOWFLAKE_LEARNING_DB.PUBLIC.RESPONSE LIMIT 5;
   ```

2. **Execute the Script:**
   ```sql
   -- Run the entire RESPONSE_FLATTEN.sql script
   -- Or execute in sections:
   
   -- Step 1: Create table
   CREATE TABLE IF NOT EXISTS ...
   
   -- Step 2: Insert data
   INSERT INTO ...
   ```

3. **Verify Results:**
   ```sql
   -- Check record count
   SELECT COUNT(*) FROM SNOWFLAKE_LEARNING_DB.PUBLIC.RESPONSE_FLATTEN;
   
   -- Sample the data
   SELECT * FROM SNOWFLAKE_LEARNING_DB.PUBLIC.RESPONSE_FLATTEN LIMIT 10;
   ```

4. **Run Verification Queries:**
   Execute the verification queries provided at the end of the script.

---

### Verification

#### **Test Cases**

**Test Case 1: Date Format Validation**
```sql
SELECT 
    COUNT(*) AS total_records,
    SUM(CASE WHEN lastResponseDate REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN 1 ELSE 0 END) AS valid_dates,
    SUM(CASE WHEN lastResponseDate REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN 0 ELSE 1 END) AS invalid_dates
FROM SNOWFLAKE_LEARNING_DB.PUBLIC.RESPONSE_FLATTEN;
```

**Expected Result:** All dates should match the MM/DD/YYYY pattern.

**Test Case 2: Length Validation**
```sql
SELECT 
    COUNT(*) AS total_records,
    SUM(CASE WHEN LENGTH(workplaceEidValidated) <= 3 THEN 1 ELSE 0 END) AS valid_length,
    SUM(CASE WHEN LENGTH(workplaceEidValidated) > 3 THEN 1 ELSE 0 END) AS invalid_length
FROM SNOWFLAKE_LEARNING_DB.PUBLIC.RESPONSE_FLATTEN;
```

**Expected Result:** All `workplaceEidValidated` values should be ≤3 characters.

---

### Performance Considerations

- **Parsing Overhead:** `PARSE_JSON()` is called multiple times per row. For large datasets, consider using a single parse with column extraction.
- **Indexing:** Consider adding indexes on frequently queried columns like `cegedimRequestEid` or `clientRequestId`.
- **Incremental Loads:** For ongoing data loads, consider using `MERGE` instead of `INSERT` to handle updates.

---

### Troubleshooting

**Issue:** Date conversion fails  
**Solution:** Check that all `lastResponseDate` values are valid ISO 8601 timestamps. Add error handling:
```sql
TRY_TO_TIMESTAMP(PARSE_JSON(JSON):lastResponseDate::STRING)
```

**Issue:** NULL values in flattened columns  
**Solution:** This is expected if the source JSON has NULL or missing fields. Use `COALESCE()` if defaults are needed:
```sql
COALESCE(PARSE_JSON(JSON):fieldName::STRING, 'N/A') AS fieldName
```

---

## 🤝 Contributing

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/NewScript`)
3. Add comprehensive comments to your SQL code
4. Update documentation in README.md
5. Submit a pull request

---

## 📝 License

This project is licensed under the MIT License.

---

## 📧 Contact

**Author:** Jishnu K Nair  
**Email:** jishnuk.nair@iqvia.com  
**GitHub:** [@jishnuunni10](https://github.com/jishnuunni10)

---

## 🔖 Version History

| Version | Date | Description | Jira Ticket |
|---------|------|-------------|--------------|
| 1.0.0 | 2026-02-05 | Initial release - RESPONSE_FLATTEN script | SCRUM-9 |

---

**⭐ If you find this repository helpful, please consider giving it a star!**
