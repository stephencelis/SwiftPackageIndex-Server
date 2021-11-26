// Copyright 2020-2021 Dave Verwer, Sven A. Schmidt, and other contributors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import Plot


extension SearchShow {

    class View: PublicPage {

        let model: Model

        init(path: String, model: Model) {
            self.model = model
            super.init(path: path)
        }

        override func pageTitle() -> String? {
            if model.query.count > 0 {
                return "Search Results for &ldquo;\(model.term)&rdquo;"
            } else {
                return "Search"
            }
        }

        override func content() -> Node<HTML.BodyContext> {
            .group(
                .section(
                    .class("search"),
                    .searchForm(query: model.query)
                ),
                .if(model.query.count > 0, resultsSection())
            )
        }

        override func navMenuItems() -> [NavMenuItem] {
            [.sponsorCTA, .addPackage, .blog, .faq]
        }

        func resultsSection() -> Node<HTML.BodyContext> {
            .section(
                .class("search_results"),
                .p(
                    // If there are *any* results, either author, keyword, or package.
                    .if(model.response.results.count > 0, .text("Results for "), else: .text("No results for ")),
                    .text("&ldquo;"),
                    .strong(.text(model.term)),
                    .text("&rdquo;"),
                    .if(model.response.results.count > 0, .text("&hellip;"), else: .text("."))
                ),
                .if(model.authorResults.count > 0 || model.keywordResults.count > 0, .div(
                    .class("two_column mobile_reversed"),
                    packageResultsSection(),
                    .div(
                        authorResultsSection(),
                        keywordResultsSection()
                    )
                ), else: packageResultsSection())
            )
        }

        func packageResultsSection() -> Node<HTML.BodyContext> {
            guard model.packageResults.count > 0
            else { return .empty }

            return .section(
                .class("package_results"),
                .h4("Matching packages\(model.filters.isEmpty ? "" : " where&hellip;")"),
                .if(model.filters.isEmpty == false,
                    .ul(
                        .id("filter_list"),
                        .group(
                            model.filters.map {
                                .li(
                                    .span(
                                        .class("filter-key"),
                                        .text($0.key)
                                    ),
                                    .text(" "),
                                    .span(
                                        .class("filter-comparison"),
                                        .text($0.comparison.userFacingString)
                                    ),
                                    .text(" "),
                                    .span(
                                        .class("filter-value"),
                                        .text($0.value)
                                    )
                                )
                            }
                        )
                    )
                ),
                .ul(
                    .id("package_list"),
                    // Let the JavaScript know that keyboard navigation on this package list should
                    // also include navigation into and out of the query field.
                    .data(named: "focus-query-field", value: String(true)),
                    .group(
                        model.packageResults.map { .packageListItem(linkUrl: $0.packageURL, packageName: $0.packageName ?? $0.repositoryName, summary: $0.summary, repositoryOwner: $0.repositoryOwner, repositoryName: $0.repositoryName, stars: $0.stars) }
                    )
                ),
                .ul(
                    .class("pagination"),
                    .if(model.page > 1, .previousPage(model: model)),
                    .if(model.response.hasMoreResults, .nextPage(model: model))
                )
            )
        }

        func authorResultsSection() -> Node<HTML.BodyContext> {
            guard model.authorResults.count > 0
            else { return .empty }

            return .section(
                .class("author_results"),
                .h4("Matching authors"),
                .ul(
                    .group(
                        model.authorResults.map { result in
                            .li(
                                .a(
                                    .href(SiteURL.author(.value(result.name)).relativeURL()),
                                    .text(result.name)
                                )
                            )
                        }
                    )
                )
            )
        }

        func keywordResultsSection() -> Node<HTML.BodyContext> {
            guard model.keywordResults.count > 0
            else { return .empty }

            return .section(
                .class("keyword_results"),
                .h4("Matching keywords"),
                .ul(
                    .class("keywords"),
                    .group(
                        model.keywordResults.map { result in
                            .li(
                                .a(
                                    .href(SiteURL.keywords(.value(result.keyword)).relativeURL()),
                                    .text(result.keyword)
                                )
                            )
                        }
                    )
                )
            )
        }
    }
}


fileprivate extension Node where Context == HTML.ListContext {
    static func previousPage(model: SearchShow.Model) -> Node<HTML.ListContext> {
        let parameters = [
            QueryParameter(key: "query", value: model.query),
            QueryParameter(key: "page", value: model.page - 1)
        ]
        return .li(
            .class("previous"),
            .a(
                .href(SiteURL.search.relativeURL(parameters: parameters)),
                "Previous Page"
            )
        )
    }

    static func nextPage(model: SearchShow.Model) -> Node<HTML.ListContext> {
        let parameters = [
            QueryParameter(key: "query", value: model.query),
            QueryParameter(key: "page", value: model.page + 1)
        ]
        return .li(
            .class("next"),
            .a(
                .href(SiteURL.search.relativeURL(parameters: parameters)),
                "Next Page"
            )
        )
    }
}
