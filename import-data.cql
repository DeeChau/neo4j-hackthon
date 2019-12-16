// General loading scheme 
// - LOAD main labels WITH main identifier
// - INDEX on these labels' main identifiers
// Add relationships/properties as fit.

// Merchant - id, name
USING PERIODIC COMMIT 1000
LOAD CSV WITH HEADERS FROM "file:///old/merchants.csv" AS row
CREATE (:Merchant {id: row.id}); //merchantName: row.name}); // TODO - Merge in AFTER relations

CREATE INDEX ON :Merchant(id);

// FSA - fsa, city
USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///fsa.csv" AS row
CREATE (:Fsa {fsa: row.fsa});//, city: row.city}); // TODO - Merge in AFTER relations

CREATE INDEX ON :Fsa(fsa);

// Google Categories google_category_id, name
USING PERIODIC COMMIT 1000
LOAD CSV WITH HEADERS FROM "file:///google_categories.csv" AS row
MERGE (:GoogleCategory {id: row.google_category_id}); //, name: row.name}) // TODO - Merge in AFTER relations

CREATE INDEX ON :GoogleCategory(id);

// UserInfo (User) account_guid,device_platform,fsa
USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///user_info.csv" AS row
CREATE (:User {guid: row.account_guid}); //, devicePlatform: row.device_platform}) // TODO - Merge in AFTER relations

CREATE INDEX ON :User(guid);

// SearchTerm
USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///search_terms.csv" AS row
CREATE (:SearchTerm {query: row.query});

CREATE INDEX ON :SearchTerm(query);

// Flyer - merchant_id,flyer_id
USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///merchant_flyer.csv" AS row
CREATE (:Flyer {id: row.flyer_id});

CREATE INDEX ON :Flyer(id);

// Flyer Item - flyer_id,flyer_item_id,name,brand,price,google_category_id
USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///flyer_flyer_item-split-a.csv" AS row
CREATE (:FlyerItem {id: row.flyer_item_id});
USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///flyer_flyer_item-split-b.csv" AS row
CREATE (:FlyerItem {id: row.flyer_item_id});
//, name: row.name, brand: row.brand, price: row.price}) // TODO - Merge in AFTER relations
CREATE INDEX ON :FlyerItem(id);

// DROP INDEXES
DROP INDEX ON :Merchant(id);

DROP INDEX ON :Fsa(fsa);

DROP INDEX ON :GoogleCategory(id);

DROP INDEX ON :User(guid);

DROP INDEX ON :Flyer(id);

DROP INDEX ON :FlyerItem(id);

DROP INDEX ON :SearchTerm(query);

// RELATIONSHIPS

// TODO
// User <-> Fsa - account_guid,fsa -- TOO SLOW?
USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///user_info.csv" AS row
MERGE (u:User {guid: row.account_guid})
MERGE (fsa:Fsa  {fsa: row.fsa})
MERGE (u)-[r:HAS_FSA]->(fsa)

// User -> Flyer
USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///user_flyer.csv" AS row
MERGE (f:Flyer {id: row.flyer_id})
MERGE (u:User {guid: row.account_guid})
MERGE (u)-[r:OPENED  {count: row.opens}]->(f)
MERGE (u)-[s:ENGAGED {count: row.evs}]->(f)

// User -> Flyer Item
USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///user_flyer_item.csv" AS row
MERGE (fi:FlyerItem {id: row.flyer_item_id})
MERGE (u:User {guid: row.account_guid})
MERGE (u)-[:CLIPPED {count: row.clippings}]->(fi)

// User -> user_flyer_item_clicks
USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///user_flyer_item_clicks.csv" AS row
MERGE (u:User {guid: row.account_guid})
MERGE (fi:FlyerItem {id: row.flyer_item_id})
MERGE (u)-[:CLICKED {count: row.clicks}]->(fi)

// TODO
// Flyer -> FSA -- TOO SLOW?
USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///flyer_fsa.csv" AS row
MERGE (f: Flyer {id: row.flyer_id})
MERGE (fsa: Fsa {fsa: row.fsa})
MERGE (m)-[r:HAS_FSA]->(fsa)

// 
// Flyer <- Merchant merchant_id,flyer_id
USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///merchant_flyer.csv" AS row
MERGE (f: Flyer {id: row.flyer_id})
MERGE (m: Merchant {id: row.merchant_id})
MERGE (m)-[r:HAS_FLYER]->(f)

// 
// Flyer <-> Flyer Item - flyer_id,flyer_item_id
USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///flyer_flyer_item-split-a.csv" AS row
// LOAD CSV WITH HEADERS FROM "file:///flyer_flyer_item-split-b.csv" AS row
MATCH (f:  Flyer {id: row.flyer_id})
MERGE (fi: FlyerItem {id: row.flyer_item_id})
MERGE (f)-[r:HAS_ITEM]->(fi)

// TODO
// Flyer Item -> Google Category
// do FlyerItemId to GoogleCategory after
USING PERIODIC COMMIT 10000
// LOAD CSV WITH HEADERS FROM "file:///flyer_flyer_item-split-a.csv" AS row
LOAD CSV WITH HEADERS FROM "file:///flyer_flyer_item-split-b.csv" AS row
MERGE (gc: GoogleCategory {id: row.google_category_id})
MERGE (fi: FlyerItem {id: row.flyer_item_id})
MERGE (fi)-[r:HAS_CATEGORY]->(gc)

// ADDITIONAL INFO

// DONE
// MERCHANT
USING PERIODIC COMMIT 1000
LOAD CSV WITH HEADERS FROM "file:///old/merchants.csv" AS row
MATCH (m:Merchant {id: row.id})
SET m.name = row.name

// GC 
USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///google_categories.csv" AS row
MATCH (gc:GoogleCategory {id: row.google_category_id})
SET gc.name = row.name

USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///flyer_flyer_item-split-a.csv" AS row
MATCH (fi:FlyerItem {id: row.flyer_item_id})
SET fi.price = toFloat(row.price);

USING PERIODIC COMMIT 10000
LOAD CSV WITH HEADERS FROM "file:///flyer_flyer_item-split-b.csv" AS row
MATCH (fi:FlyerItem {id: row.flyer_item_id})
SET fi.price = toFloat(row.price);


///////////////////////////// DEMO /////////////////////////////

//// USERS
MATCH (u:User)-[c:CLICKED]->(:FlyerItem)
WITH u, SUM(toInteger(c.count)) as clicks
ORDER BY clicks DESC
RETURN DISTINCT u
LIMIT 10

// Users with the most CLICKS!
MATCH (u:User)-[c:CLICKED]->(:FlyerItem)
WITH u, SUM(toInteger(c.count)) as clicks
ORDER BY clicks DESC
RETURN DISTINCT u.guid, clicks
LIMIT 10

// POGGERS

//// ITEMS

// A user's clicked items!
MATCH p=(u1:User {guid: "c4da90dc-6f64-4d40-9c60-4926b27aa61d"})-[:CLICKED]->(fi1:FlyerItem)
RETURN p
// Next 5 Best Items:
EXPLAIN
MATCH p=(u1:User {guid: "c4da90dc-6f64-4d40-9c60-4926b27aa61d"})-[:CLICKED]->(fi1:FlyerItem)<-[:CLICKED]-(u2:User)-[c:CLICKED]->(fi2:FlyerItem)
WHERE u1 <> u2 AND fi1 <> fi2
WITH u1, fi2, SUM(toInteger(c.count)) as clicks
ORDER BY clicks DESC
RETURN fi2.name, clicks
LIMIT 5

// Visualize
MATCH p=(u1:User {guid: "c4da90dc-6f64-4d40-9c60-4926b27aa61d"})-[:CLICKED]->(fi1:FlyerItem)<-[:CLICKED]-(u2:User)-[c:CLICKED]->(fi2:FlyerItem)
WHERE u1 <> u2 AND fi1 <> fi2
WITH u1, fi2, SUM(toInteger(c.count)) as clicks, p
ORDER BY clicks DESC
RETURN p
LIMIT 20

// Deep dive into an item!
MATCH (f:FlyerItem {id: "457444119"})
RETURN f
// Can click into

// Next Best Related Flyer Item:
MATCH p1=(u1:User {guid: "c4da90dc-6f64-4d40-9c60-4926b27aa61d"})-[:CLICKED]->(fi1:FlyerItem)<-[:CLICKED]-(u2:User)-[c:CLICKED]->(fi2:FlyerItem),
      p2=(fi1)-[:HAS_CATEGORY]->(gc:GoogleCategory)<-[:HAS_CATEGORY]-(fi2)
WHERE u1 <> u2 AND fi1 <> fi2
WITH fi2,p1, SUM(toInteger(c.count)) as clicks 
ORDER BY clicks DESC
RETURN fi2.id, clicks
LIMIT 20

MATCH p1=(u1:User {guid: "c4da90dc-6f64-4d40-9c60-4926b27aa61d"})-[:CLICKED]->(fi1:FlyerItem)<-[:CLICKED]-(u2:User)-[c:CLICKED]->(fi2:FlyerItem),
      p2=(fi1)-[:HAS_CATEGORY]->(gc:GoogleCategory)<-[:HAS_CATEGORY]-(fi2)
WHERE u1 <> u2 AND fi1 <> fi2
WITH fi2, p1, SUM(toInteger(c.count)) as clicks 
ORDER BY clicks DESC
RETURN p1
LIMIT 20

//// FLYERS

// Next 5 Best Flyers:
MATCH p=(u1:User {guid: "c4da90dc-6f64-4d40-9c60-4926b27aa61d"})-[:OPENED]->(f1:Flyer)<-[:OPENED]-(u2:User)-[o:OPENED]->(f2:Flyer)
WHERE u1 <> u2 AND f1 <> f2
WITH f2, count(toInteger(o.count)) AS opens
ORDER BY opens DESC
RETURN f2.id, opens
LIMIT 5

// Next BEST flyer (Rank 1)
MATCH p=(f:Flyer {id: "3151300"})-[:HAS_ITEM]->(:FlyerItem)-[:HAS_CATEGORY]->()
RETURN p
LIMIT 30
