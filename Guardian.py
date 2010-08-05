class Guardian:
    def get_article_urls(self):
        return ["http://www.guardian.co.uk/world/2010/jul/11/srebrenica-massacre-anniversary-killings"]
    
    def load_article(self, tokens):

        byline_state = 0
        byline_start = None
        byline_end = None
        byline = ""

        title_state = 0
        title_start = None
        title_end = None

        body_state = 0
        body_start = None
        body_end = None

        for token in tokens:

            if byline_state == 0 and token == "<li class=\"byline\">":
                byline_state = 1
            elif byline_state == 1 and token == "<a>":
                byline_state = 2
            elif byline_state == 2 and token != "</a>":
                if byline_start == None:
                    byline_start = token
                byline_end = token
                byline = byline + " " + str(token)
            elif token == "</a>" or token == "</li>":
                byline_state = 0

            if title_state == 0 and token == "<div id=\"main-article-info\">":
                title_state = 1
            elif title_state == 1 and token == "<h1>":
                title_state = 2
            elif title_state == 2 and token != "</h1>":
                if title_start == None:
                    title_start = token
                title_end = token
            elif token == "</h1>" or token == "</div>":
                title_state = 0

            if body_state == 0 and token == "<div id=\"article-wrapper\">":
                body_state = 1
                print "state 1"
            elif body_state == 1 and token == "<p>":
                body_state = 2
                print "state 2"
            elif body_state == 2 and token != "</p>" and token != "<p>":
                if body_start == None:
                    body_start = token
                body_end = token
            elif token == "</div>":
                body_state = 0


        # return value: (path_in_hierarchy, dictionary_of_fields)
        return (["authors", byline], { "body":(body_start, body_end), "title":(title_start, title_end), "byline":(byline_start, byline_end) })

the_corpus = Guardian()