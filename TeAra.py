class TeAra:
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

            if title_state == 0 and token == "<field name=\"title\">":
                title_state = 1
            elif title_state == 1 and token != "</field>":
                if title_start == None:
                    title_start = token
                title_end = token
            elif token == "</field>":
                title_state = 0

            if body_state == 0 and token == "<field name=\"body\">":
                body_state = 1
            elif body_state == 1 and token != "</field>":
                if body_start == None:
                    body_start = token
                body_end = token
            elif token == "</field>":
                body_state = 0


        # return value: (path_in_hierarchy, dictionary_of_fields)
        return ([], { "body":(body_start, body_end), "title":(title_start, title_end) })

the_corpus = Guardian()