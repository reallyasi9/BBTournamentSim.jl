Teams come from the following request:

https://picks.cbssports.com/graphql?operationName=CentralTeamsQuery&variables={"sportTypes":["NCAAB"],"subsection":null}&extensions={"persistedQuery":{"version":1,"sha256Hash":"0a75bf16d2074af6893f4386e7a17bed7f6fe04f96a00edfb75de3d5bdf527ba"}}

The response is JSON. Team IDs are mapped to team names via the data.teams[i].id and data.teams[i].shortName (or .mediumName, or .nickName, or .location, or.abbrev).

The pool ID is something you just have to know, I think.

Entries come from the following request:

https://picks.cbssports.com/graphql?operationName=PoolSeasonStandingsQuery&variables={"skipAncestorPools":false,"skipPeriodPoints":false,"gameInstanceUid":"cbs-ncaab-tournament-manager","includedEntryIds":["ivxhi4tzhi4tembzgq3dini="],"poolId":"kbxw63b2gu4tsmrzgu4q====","first":50,"orderBy":"OVERALL_RANK","sortingOrder":"ASC"}&extensions={"persistedQuery":{"version":1,"sha256Hash":"4084de9ddd4d6369c4b2625dc756a3d6974b774e746960d3cdfcf64686147d7b"}}

Find the entry ID in the JSON response at data.gameInstance.pool.entries.edges[i].node.id. The name is there, too, at ...name. Note the "first" variable in the request and adjust it appropriately.

The entry can then be queried with:

https://picks.cbssports.com/graphql?operationName=EntryDetailsQuery&variables={"periodId":"current","entryId":"ivxhi4tzhiytcnbxgq2dcmbx"}&extensions={"persistedQuery":{"version":1,"sha256Hash":"d2a67474fb3276c6f9f0b8d24eceda58de511926a9dadb7aa55f1065f67e6d85"}}&entryId=ivxhi4tzhiytcnbxgq2dcmbx

"entryId" maps to a data.gameInstance.pool.entries.edges[i].node.id value (the name of the person who owns that entry is in ...name).

