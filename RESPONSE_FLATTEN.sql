-- =====================================================
-- Script: RESPONSE_FLATTEN.sql
-- Purpose: Flatten JSON data from RESPONSE table and apply transformations
-- Author: Jishnu K Nair
-- Created: 2026-02-05
-- Jira Ticket: SCRUM-9
-- =====================================================

-- DESCRIPTION:
-- This script creates a flattened table from JSON data stored in the RESPONSE table.
-- It extracts all JSON fields into individual columns and applies specific transformations:
-- 1. Converts lastResponseDate from ISO 8601 format to MM/DD/YYYY format
-- 2. Truncates workplaceEidValidated to 3 characters

-- =====================================================
-- STEP 1: CREATE TABLE STRUCTURE
-- =====================================================
-- Creates the target table with all required columns
-- Each column is defined as VARCHAR to handle text data
-- workplaceEidValidated is specifically set to VARCHAR(3) to enforce length constraint

CREATE TABLE IF NOT EXISTS SNOWFLAKE_LEARNING_DB.PUBLIC.RESPONSE_FLATTEN (
    activityEidSource VARCHAR,
    activityEidValidated VARCHAR,
    addressEidSource VARCHAR,
    addressEidValidated VARCHAR,
    cegedimRequestEid VARCHAR,
    cisHostNum VARCHAR,
    clientRequestId VARCHAR,
    codBase VARCHAR,
    countryEid VARCHAR,
    individualEidSource VARCHAR,
    individualEidValidated VARCHAR,
    lastResponseDate VARCHAR,              -- Will store date in MM/DD/YYYY format
    processStatus VARCHAR,
    requestComment VARCHAR,
    requestEntityType VARCHAR,
    requestFirstname VARCHAR,
    requestLastname VARCHAR,
    requestOrigin VARCHAR,
    requestProcess VARCHAR,
    requestStatus VARCHAR,
    requestType VARCHAR,
    requestUsualWkpName VARCHAR,
    responseComment VARCHAR,
    responseEntityType VARCHAR,
    trace1ClientRequestDate VARCHAR,
    trace2CegedimOkcProcessDate VARCHAR,
    trace3CegedimOkeTransferDate VARCHAR,
    trace4CegedimOkeIntegrationDate VARCHAR,
    trace5CegedimDboResponseDate VARCHAR,
    trace6CegedimOkcExportDate VARCHAR,
    updateDate VARCHAR,
    userEid VARCHAR,
    workplaceEidSource VARCHAR,
    workplaceEidValidated VARCHAR(3)       -- Limited to 3 characters
);

-- =====================================================
-- STEP 2: POPULATE TABLE WITH TRANSFORMED DATA
-- =====================================================
-- Extracts JSON fields and applies transformations
-- Uses PARSE_JSON to parse the JSON string
-- Applies TO_CHAR and TO_TIMESTAMP for date formatting
-- Uses LEFT function to truncate string values

INSERT INTO SNOWFLAKE_LEARNING_DB.PUBLIC.RESPONSE_FLATTEN
SELECT 
    -- Activity EID fields
    PARSE_JSON(JSON):activityEidSource::STRING AS activityEidSource,
    PARSE_JSON(JSON):activityEidValidated::STRING AS activityEidValidated,
    
    -- Address EID fields
    PARSE_JSON(JSON):addressEidSource::STRING AS addressEidSource,
    PARSE_JSON(JSON):addressEidValidated::STRING AS addressEidValidated,
    
    -- Request identification fields
    PARSE_JSON(JSON):cegedimRequestEid::STRING AS cegedimRequestEid,
    PARSE_JSON(JSON):cisHostNum::STRING AS cisHostNum,
    PARSE_JSON(JSON):clientRequestId::STRING AS clientRequestId,
    PARSE_JSON(JSON):codBase::STRING AS codBase,
    PARSE_JSON(JSON):countryEid::STRING AS countryEid,
    
    -- Individual EID fields
    PARSE_JSON(JSON):individualEidSource::STRING AS individualEidSource,
    PARSE_JSON(JSON):individualEidValidated::STRING AS individualEidValidated,
    
    -- Date transformation: ISO 8601 -> MM/DD/YYYY
    -- Example: "2025-10-07T13:37:28Z" becomes "10/07/2025"
    TO_CHAR(TO_TIMESTAMP(PARSE_JSON(JSON):lastResponseDate::STRING), 'MM/DD/YYYY') AS lastResponseDate,
    
    -- Process status fields
    PARSE_JSON(JSON):processStatus::STRING AS processStatus,
    
    -- Request detail fields
    PARSE_JSON(JSON):requestComment::STRING AS requestComment,
    PARSE_JSON(JSON):requestEntityType::STRING AS requestEntityType,
    PARSE_JSON(JSON):requestFirstname::STRING AS requestFirstname,
    PARSE_JSON(JSON):requestLastname::STRING AS requestLastname,
    PARSE_JSON(JSON):requestOrigin::STRING AS requestOrigin,
    PARSE_JSON(JSON):requestProcess::STRING AS requestProcess,
    PARSE_JSON(JSON):requestStatus::STRING AS requestStatus,
    PARSE_JSON(JSON):requestType::STRING AS requestType,
    PARSE_JSON(JSON):requestUsualWkpName::STRING AS requestUsualWkpName,
    
    -- Response detail fields
    PARSE_JSON(JSON):responseComment::STRING AS responseComment,
    PARSE_JSON(JSON):responseEntityType::STRING AS responseEntityType,
    
    -- Trace/audit fields (timestamps for tracking request lifecycle)
    PARSE_JSON(JSON):trace1ClientRequestDate::STRING AS trace1ClientRequestDate,
    PARSE_JSON(JSON):trace2CegedimOkcProcessDate::STRING AS trace2CegedimOkcProcessDate,
    PARSE_JSON(JSON):trace3CegedimOkeTransferDate::STRING AS trace3CegedimOkeTransferDate,
    PARSE_JSON(JSON):trace4CegedimOkeIntegrationDate::STRING AS trace4CegedimOkeIntegrationDate,
    PARSE_JSON(JSON):trace5CegedimDboResponseDate::STRING AS trace5CegedimDboResponseDate,
    PARSE_JSON(JSON):trace6CegedimOkcExportDate::STRING AS trace6CegedimOkcExportDate,
    
    -- Metadata fields
    PARSE_JSON(JSON):updateDate::STRING AS updateDate,
    PARSE_JSON(JSON):userEid::STRING AS userEid,
    
    -- Workplace EID fields
    PARSE_JSON(JSON):workplaceEidSource::STRING AS workplaceEidSource,
    
    -- String truncation: Limit to 3 characters
    -- Example: "WBR123" becomes "WBR"
    LEFT(PARSE_JSON(JSON):workplaceEidValidated::STRING, 3) AS workplaceEidValidated
    
FROM SNOWFLAKE_LEARNING_DB.PUBLIC.RESPONSE;

-- =====================================================
-- STEP 3: VERIFICATION QUERIES
-- =====================================================
-- Use these queries to verify the transformation results

-- Verify date format transformation
SELECT 
    lastResponseDate,
    LENGTH(lastResponseDate) AS date_length,
    CASE 
        WHEN lastResponseDate REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$' THEN 'Valid Format'
        ELSE 'Invalid Format'
    END AS format_check
FROM SNOWFLAKE_LEARNING_DB.PUBLIC.RESPONSE_FLATTEN;

-- Verify workplaceEidValidated length
SELECT 
    workplaceEidValidated,
    LENGTH(workplaceEidValidated) AS actual_length,
    CASE 
        WHEN LENGTH(workplaceEidValidated) <= 3 THEN 'Valid Length'
        ELSE 'Invalid Length'
    END AS length_check
FROM SNOWFLAKE_LEARNING_DB.PUBLIC.RESPONSE_FLATTEN;

-- Count total records
SELECT COUNT(*) AS total_records 
FROM SNOWFLAKE_LEARNING_DB.PUBLIC.RESPONSE_FLATTEN;

-- =====================================================
-- END OF SCRIPT
-- =====================================================
