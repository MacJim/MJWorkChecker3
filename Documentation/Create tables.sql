CREATE TABLE IF NOT EXISTS WorkSegments (
    segmentID INTEGER,

    startWorkingTimestamp INTEGER NOT NULL,    -- Start working UNIX timestamp.

    stopWorkingTimestamp INTEGER NOT NULL,    -- Stop working UNIX timestamp.


    PRIMARY KEY (segmentID)
);
