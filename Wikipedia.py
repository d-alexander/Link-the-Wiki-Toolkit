class Wikipedia:
    def get_article_urls(self):
        return []
    
    def load_article(self, tokens):

        title_state = 0
        title_start = None
        title_end = None

        body_state = 0
        body_start = None
        body_end = None

        for token in tokens:

            if title_state == 0 and token == "<name>":
                title_state = 1
            elif title_state == 1 and token != "</name>":
                if title_start == None:
                    title_start = token
                title_end = token
            elif token == "</name>":
                title_state = 0

            if body_state == 0 and token == "</name>":
                body_state = 1
            elif body_state == 1:
                if body_start == None:
                    body_start = token
                body_end = token


        # return value: (path_in_hierarchy, dictionary_of_fields)
        return ([], { "body":(body_start, body_end), "title":(title_start, title_end) })

the_corpus = Wikipedia()