//
//  main.m
//  LTWKLDivergenceCalculator
//
//  Created by David Alexander on 18/08/10.
//  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>

#import "LTWTokens.h"
#import "LTWCorpus.h"
#import "LTWArticle.h"

#define CREATE_STATEMENT(x, y) sqlite3_stmt * x##Stmt = NULL; const char * x##Query = y;
#define INIT_STATEMENT(x) [[LTWDatabase sharedInstance] initialiseStatement:&(x##Stmt) withQuery:(x##Query)]

void sqlLog2Func(sqlite3_context *context, int argc, sqlite3_value **argv) {
    double n = sqlite3_value_double(argv[0]);
    sqlite3_result_double(context, log2(n));
}

int min(int a, int b) {
    return (a < b) ? a : b;
}

int max(int a, int b) {
    return (a > b) ? a : b;
}

void KLDRun() {
    NSDirectoryEnumerator *enumerator;
    NSString *filename;
    NSUInteger filesProcessed = 0;
    
    CREATE_STATEMENT(loadWords, "SELECT id, word FROM words");
    CREATE_STATEMENT(setUpMemoryTables1, "ATTACH DATABASE ':memory:' AS mem;");
    CREATE_STATEMENT(setUpMemoryTables2, "CREATE TABLE mem.top_mappings (ta_article_id INT, wp_article_id INT, divergence REAL);");
    CREATE_STATEMENT(setUpMemoryTables3, "CREATE TABLE mem.current_terms (word_id INT);");
    CREATE_STATEMENT(setUpMemoryTables4, "CREATE INDEX mem.current_terms_index ON current_terms (word_id);");
    CREATE_STATEMENT(setUpMemoryTables5, "CREATE TABLE mem.current_term_frequencies (word_id INT, count INT);");
    CREATE_STATEMENT(setUpMemoryTables6, "CREATE INDEX mem.current_term_frequencies_index ON current_term_freqiencies (word_id);");
    CREATE_STATEMENT(clearTerms, "DELETE FROM current_terms;");
    CREATE_STATEMENT(clearTermFrequencies, "DELETE FROM current_term_frequencies;");
    CREATE_STATEMENT(addTerm, "INSERT INTO mem.current_terms VALUES (?);");
    CREATE_STATEMENT(calculateTermFrequencies, "INSERT INTO mem.current_term_frequencies SELECT word_id, COUNT(*) AS count FROM mem.current_terms GROUP BY word_id;");
    
    // This query finds the KL-divergences of every Te Ara article with the Wikipedia article whose term-frequencies are currently in memory.current_term_frequencies. The length of the Wikipedia article (in tokens) is a bound parameter.
    // TODO: Make it update the current "best" divergences.
    //CREATE_STATEMENT(updateDivergences, "SELECT ta_tfs.tokens_id, SUM((ta_tfs.count / ta_lengths.length) * LOG2( (ta_tfs.count / ta_lengths.length) / (wp_tfs.count / ?) )) AS divergence FROM word_occurrences ta_tfs JOIN mem.current_term_frequencies wp_tfs ON ta_tfs.word_id = wp_tfs.word_id JOIN tokens_lengths ta_lengths ON ta_tfs.tokens_id = ta_lengths.tokens_id GROUP BY ta_tfs.tokens_id;");
    CREATE_STATEMENT(updateDivergences, "SELECT ta_tfs.tokens_id, SUM((ta_tfs.count / (ta_lengths.length+0.0)) * LOG2( (ta_tfs.count / (ta_lengths.length+0.0)) / (wp_tfs.count / (?+0.0)) )) AS divergence FROM mem.current_term_frequencies wp_tfs NATURAL JOIN word_occurrences ta_tfs NATURAL JOIN tokens_lengths ta_lengths GROUP BY ta_tfs.tokens_id ORDER BY divergence LIMIT 10;");
    
    [LTWDatabase setSharedDatabaseFile:[@""DATA_PATH stringByAppendingPathComponent:@"te_ara_index.db"]];
    
    sqlite3_create_function([[LTWDatabase sharedInstance] databaseConnection], "LOG2", 1, SQLITE_ANY, NULL, sqlLog2Func, NULL, NULL);
    
    
    INIT_STATEMENT(setUpMemoryTables1);
    sqlite3_step(setUpMemoryTables1Stmt);
    INIT_STATEMENT(setUpMemoryTables2);
    sqlite3_step(setUpMemoryTables2Stmt);
    INIT_STATEMENT(setUpMemoryTables3);
    sqlite3_step(setUpMemoryTables3Stmt);
    INIT_STATEMENT(setUpMemoryTables4);
    sqlite3_step(setUpMemoryTables4Stmt);
    INIT_STATEMENT(setUpMemoryTables5);
    sqlite3_step(setUpMemoryTables5Stmt);
    INIT_STATEMENT(setUpMemoryTables6);
    sqlite3_step(setUpMemoryTables6Stmt);
    
    INIT_STATEMENT(loadWords);
    NSMutableDictionary *wordIDs = [NSMutableDictionary dictionary];
    
    while (SQLITE_ROW == sqlite3_step(loadWordsStmt)) {
        int wordID = sqlite3_column_int(loadWordsStmt, 0);
        const unsigned char *word = sqlite3_column_text(loadWordsStmt, 1);
        
        [wordIDs setObject:[NSNumber numberWithInt:wordID] forKey:[NSString stringWithUTF8String:word]];
    }
    
    for (enumerator = [[NSFileManager defaultManager] enumeratorAtPath:@"/Users/david/Desktop/phd/wp2007/"];
         filename = [enumerator nextObject]; ) {
        
        NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
        
        LTWTokens *tokens = [[LTWTokens alloc] initWithXML:[NSString stringWithContentsOfFile:[@"/Users/david/Desktop/phd/wp2007/" stringByAppendingString:filename]]];
        
        INIT_STATEMENT(clearTerms);
        sqlite3_step(clearTermsStmt);
        INIT_STATEMENT(clearTermFrequencies);
        sqlite3_step(clearTermFrequenciesStmt);
        
        [[LTWDatabase sharedInstance] beginTransaction];
        
        for (NSUInteger tokenIndex = 0; tokenIndex < [tokens count]; tokenIndex++) {
            
            NSString *tokenString = [[tokens _text] substringWithRange:[tokens rangeOfTokenAtIndex:tokenIndex]];
            
            NSUInteger wordID = [[wordIDs objectForKey:tokenString] intValue];
            
            INIT_STATEMENT(addTerm);
            sqlite3_bind_int(addTermStmt, 1, wordID);
            sqlite3_step(addTermStmt);
            
        }
        
        
        INIT_STATEMENT(calculateTermFrequencies);
        sqlite3_step(calculateTermFrequenciesStmt);
        
        [[LTWDatabase sharedInstance] commit];
        
        if ([tokens count] > 0) {
            INIT_STATEMENT(updateDivergences);
            sqlite3_bind_int(updateDivergencesStmt, 1, [tokens count]);
            //sqlite3_step(updateDivergencesStmt);
            
            
            while (SQLITE_ROW == sqlite3_step(updateDivergencesStmt)) {
                NSUInteger ta_article = sqlite3_column_int(updateDivergencesStmt, 0);
                double divergence = sqlite3_column_double(updateDivergencesStmt, 1);
                if (divergence != 0) NSLog(@"WP = %@, TA (tokens_id) = %d, DIVERGENCE = %lf", filename, ta_article, divergence);
                
            }
        }
        
        if (++filesProcessed % 1 == 0) {
            NSLog(@"%u files processed.", filesProcessed);
        }
        
        [loopPool release];
    }
    
    [LTWDatabase stopAsynchronousThread];
}

void TitleRunPhase1() {
    [LTWDatabase setSharedDatabaseFile:[@""DATA_PATH stringByAppendingPathComponent:@"te_ara_articles_temp.db"]];
    
    [[LTWDatabase sharedInstance] beginTransaction];
    
    LTWCorpus *corpus = [[LTWCorpus alloc] initWithImplementationCode:[NSString stringWithContentsOfURL:[NSURL URLWithString:@"file:///Users/david/Dropbox/phd/code/LTWToolkit/TeAra.py"]]];
    
    NSMutableDictionary *articleTitles = [NSMutableDictionary dictionary];
    
    NSUInteger articlesProcessed = 0;
    NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
    
    for (NSString *urlString in [corpus articleURLs]) {
        LTWArticle *article = [corpus loadArticleWithURL:[NSURL URLWithString:urlString]];
        
        [article pageOut];
        
        if (++articlesProcessed % 100 == 0) {
            NSLog(@"%u articles processed [phase 1]", articlesProcessed);
            [[LTWDatabase sharedInstance] commit];
            [[LTWDatabase sharedInstance] beginTransaction];
            [loopPool drain];
            loopPool = [[NSAutoreleasePool alloc] init];
        }
    }
    
    [[LTWDatabase sharedInstance] commit];
    [LTWDatabase stopAsynchronousThread];
    [loopPool drain];
}
 
void TitleRunPhase2() {
    [LTWDatabase setSharedDatabaseFile:[@""DATA_PATH stringByAppendingPathComponent:@"te_ara_articles_temp.db"]];
    
    [[LTWDatabase sharedInstance] beginTransaction];
    
    LTWCorpus *corpus = [[LTWCorpus alloc] initWithImplementationCode:[NSString stringWithContentsOfURL:[NSURL URLWithString:@"file:///Users/david/Dropbox/phd/code/LTWToolkit/TeAra.py"]]];
    
    NSUInteger articlesProcessed = 0;
    NSAutoreleasePool *loopPool = [[NSAutoreleasePool alloc] init];
    
    /*
    for (NSString *urlString in [corpus articleURLs]) {
        LTWArticle *article = [corpus loadArticleWithURL:[NSURL URLWithString:urlString]];
        
        LTWTokens *tokens = [article tokensForField:@"body"];
        
        // TODO: Possibly put a limit on how small the anchor text can get (relative to the target title?)
        for (NSUInteger tokenIndex = 0; tokenIndex < [tokens count]; tokenIndex++) {
            
            NSMutableString *candidate = [NSMutableString string];
            for (NSUInteger candidateTokenIndex = tokenIndex; candidateTokenIndex < min(tokenIndex + longestTitleLength, [tokens count]); candidateTokenIndex++) {
                if (candidateTokenIndex > tokenIndex) [candidate appendString:@" "];
                [candidate appendString:[[[tokens _text] substringWithRange:[tokens rangeOfTokenAtIndex:candidateTokenIndex]] lowercaseString]];
            }
            
            NSUInteger lastToken = min(tokenIndex + longestTitleLength, [tokens count]) - 1;
            
            while (lastToken >= tokenIndex) {
                id candidateTarget = [articleTitles objectForKey:candidate];
                
                if (candidateTarget) {
                    NSLog(@"target found for candidate %@, title %@", [candidateTarget tokensForField:@"title"]);
                    
                    [tokens _addTag:[[LTWTokenTag alloc] initWithName:@"linked_to" value:candidateTarget] fromIndex:tokenIndex toIndex:lastToken];
                    break;
                }
                
                NSRange lastTokenRange = [tokens rangeOfTokenAtIndex:lastToken];
                NSUInteger removeStart = [candidate length] - lastTokenRange.length;
                if (removeStart > 0) removeStart--; // remove the space before the token as well.
                [candidate deleteCharactersInRange:NSMakeRange(removeStart, [candidate length] - removeStart)];
                
                lastToken--;
            }
        }
        
        if (++articlesProcessed % 100 == 0) {
            NSLog(@"%u articles processed [phase 2]", articlesProcessed);
            [[LTWDatabase sharedInstance] commit];
            [[LTWDatabase sharedInstance] beginTransaction];
            [loopPool drain];
            loopPool = [[NSAutoreleasePool alloc] init];
        }
    }
     */
    
    [[LTWDatabase sharedInstance] commit];
    [LTWDatabase stopAsynchronousThread];
    [loopPool drain];

}

int main (int argc, const char * argv[]) {

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
    //KLDRun();
    TitleRunPhase1();
    
    [pool drain];
    return 0;
}

