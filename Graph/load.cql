// Hurun China unicorns index

// uniqueness CONSTRAINT
CREATE CONSTRAINT ON (c:Company) ASSERT c.name IS UNIQUE;
CREATE CONSTRAINT ON (on:Industry) ASSERT on.name IS UNIQUE;
CREATE CONSTRAINT ON (at:City) ASSERT at.name IS UNIQUE;
CREATE CONSTRAINT ON (i:Investor) ASSERT i.name IS UNIQUE;

// load companies data
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM "file:///china-unicorn-index/Data/companies.csv" AS line
CREATE (comp:Company {name: line.company, ranking: toInteger(line.ranking), valuation: toInteger(line.valuation), key_person: line.key_person})
MERGE (ind:Industry {name: line.industry})
MERGE (city:City {name: line.headquarter})
CREATE (comp)-[:based_in]->(city)
CREATE (comp)-[:belongs]->(ind)
;

// load investors data
USING PERIODIC COMMIT
LOAD CSV WITH HEADERS
FROM "file:///china-unicorn-index/Data/investors.csv" AS line
MERGE (investor:Investor{name: line.investor})
MERGE (company:Company {name: line.company})
CREATE (investor)-[:invests_in]->(company)
;
