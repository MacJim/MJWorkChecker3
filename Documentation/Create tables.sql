/**
 * Total working duration of each day.
 */
CREATE TABLE IF NOT EXISTS Days (
    dayID INTEGER,

    startOfDayTimestamp INTEGER NOT NULL,    -- The day's start timestamp. Used for sorting and finding days.

    year INTEGER,    -- 2019

    month INTEGER,    -- 11

    day INTEGER,    -- 29

    totalWorkingDuration INTEGER NOT NULL,    -- Total working duration on that specific day.


    PRIMARY KEY (dayID)
);

CREATE INDEX IF NOT EXISTS Days_startOfDayTimestamp ON Days(startOfDayTimestamp);

-- CREATE INDEX IF NOT EXISTS Days_month ON Days(month);    -- Currently not used.


CREATE TABLE IF NOT EXISTS WorkSegments (
    segmentID INTEGER,

    startWorkingTimestamp INTEGER NOT NULL,    -- Start working UNIX timestamp.

    stopWorkingTimestamp INTEGER NOT NULL,    -- Stop working UNIX timestamp.

    dayID INTEGER,


    PRIMARY KEY (segmentID),

    FOREIGN KEY (dayID) REFERENCES Days(dayID) ON DELETE SET NULL
);

-- CREATE INDEX IF NOT EXISTS WorkSegments_startWorkingTimestamp ON WorkSegments (startWorkingTimestamp);    -- No longer used.

-- CREATE INDEX IF NOT EXISTS WorkSegments_stopWorkingTimestamp ON WorkSegments (stopWorkingTimestamp);    -- Currently not used.

CREATE INDEX IF NOT EXISTS WorkSegments_dayID ON WorkSegments(dayID);
