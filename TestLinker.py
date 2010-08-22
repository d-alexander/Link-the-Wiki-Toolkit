import ltw

class TestLinker:
    def get_initial_searches(self):
        return [("entire_field", None, "teara", None, "title", TestLinker.found_title, None)]

    def found_title(self, tokens, arg):
        print "Found title: " + str(tokens)
        ltw.tag_range(tokens, "linked_to", tokens) # should ideally make this link to something random
        return []

the_corpus = TestLinker()