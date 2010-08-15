import ltw

class WPTAMapping:
    def get_initial_searches(self):
        return [("entire_field", None, "wikipedia", None, "title", WPTAMapping.found_wp_title, None), ("tag", ("mapped_from", None), "wikipedia", None, "body", WPTAMapping.found_mapping, None)]

    def found_wp_title(self, tokens, arg):
        return [("bounded", ("<h3>", tokens, "</h3>"), "teara", None, "body", WPTAMapping.found_wp_title_in_ta_heading, tokens.associated_field("body"))]

    def found_wp_title_in_ta_heading(self, tokens, arg):
        wp_article_body = arg
        wp_tag = ltw.tag_range(wp_article_body, "mapped_from", tokens)
        ta_tag = ltw.tag_range(tokens, "mapped_to", wp_article_body)
        return [] # NOTE: We don't have to return the tags; they're automatically set after the method returns.

    def found_mapping(self, tokens, arg):
        searches = []
        for token in tokens:
            if token == "<collectionlink>": # Not sure if this is the correct tag-name.
                href = token.xml_attribute("href") # Is the method-name "attribute" reserved?
                search = ["tag", ("mapped_from", None), "wikipedia", href, "body", WPTAMapping.found_linked_mapped_articles, tokens]
                searches = searches + search
        return searches

    def found_linked_mapped_articles(self, tokens, arg):
        source_wp_article = arg
        destination_wp_article = tokens
        source_ta_article = ltw.tag_value(source_wp_article, "mapped_from")
        destination_ta_article = ltw.tag_value(destination_wp_article, "mapped_from")
        link_tag = ltw.tag_range(source_ta_article, "linked_to", destination_ta_article)
        return []

the_corpus = WPTAMapping()