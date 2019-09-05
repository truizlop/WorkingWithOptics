import Bow
import BowOptics

/*:
 # Working effectively with immutable data structures using Bow Optics
 
 ## Tomás Ruiz-López ([@tomasruizlopez](https://twitter.com/tomasruizlopez)) - Tech Lead at 47 Degrees
 
 - [Website](https://bow-swift.io/docs/optics/overview/)
 - [GitHub repository](https://github.com/bow-swift/bow)
 - Twitter [@bow_swift](https://twitter.com/bow_swift)
 
 **Problem**: We are modeling a website with a blog. Blogs have Articles with a title, an optional subtitle, a publication state (draft or published), and an author. For authors, we want to display their names and social media accounts (Twitter or Github).
 
 We can create multiple value objects to represent this model:
 */

enum SocialMedia {
  case twitter(String)
  case github(String)
}

struct Author {
  var name: String
  var social: [SocialMedia]
}

enum PublicationState {
  case draft
  case published(Date)
}

struct Article {
  var title: String
  var subtitle: Option<String>
  var state: PublicationState
  var author: Author
}

struct Blog {
  var articles: [Article]
}

let blog = Blog(
  articles: [
    Article(
      title: "Writing your own optics",
      subtitle: .none(),
      state: .draft,
      author:
      Author(name: "Tomás Ruiz-López",
             social: [.twitter("tomasruizlopez"),
                      .github("truizlop")
        ])
    ),
    Article(
      title: "nef 0.3.0 now available",
      subtitle: .some("Super powers for your Playgrounds"),
      state: .published(Date()),
      author:
      Author(name: "Miguel Ángel Díaz",
             social: [.twitter("miguelangel_dl")])
    )
  ]
)

extension SocialMedia: CustomStringConvertible {
  var description: String {
    switch self {
    case let .github(username): return "🐙(\(username))"
    case let .twitter(handle): return "🕊(\(handle))"
    }
  }
}

extension Author: CustomStringConvertible {
  var description: String {
    let socialDescription = social.map { $0.description }.joined(separator: ", ")
    return "👨🏻‍💻 by \(name) - \(socialDescription)"
  }
}

extension PublicationState: CustomStringConvertible {
  var description: String {
    switch self {
    case .draft: return "🖊"
    case .published(_): return "✅"
    }
  }
}

extension Article: CustomStringConvertible {
  var description: String {
    return "\(title) - \(state)\n\t\(subtitle.fold({ "~" }, id))\n\t\(author)"
  }
}

extension Blog: CustomStringConvertible {
  var description: String {
    let articlesDescription = articles.map { "📄 \($0.description)" }.joined(separator: "\n\n")
    return "In the blog:\n\(articlesDescription)"
  }
}

print(blog)

func addAtToTwitterHandle(in blog: Blog) -> Blog {
  return Blog(articles: blog.articles.map { article in
    Article(
      title: article.title,
      subtitle: article.subtitle,
      state: article.state,
      author:
      Author(
        name: article.author.name,
        social: article.author.social.map { social in
          if case let .twitter(handle) = social {
            return .twitter("@\(handle)")
          } else {
            return social
          }
      })
    )
    }
  )
}

print("------------------")
print("After adding @")
print(addAtToTwitterHandle(in: blog))
print("------------------")
//: Getters
let titleGetter = Getter<Article, String> { article in article.title }

extension Article: AutoGetter {}
let titleGetter2 = Article.getter(for: \.title)
//: Setters
let titleSetter = Setter<Article, String> { modify in
  return { article in Article(title: modify(article.title), subtitle: article.subtitle, state: article.state, author: article.author) }
}

extension Article: AutoSetter {}
let titleSetter2 = Article.setter(for: \.title)
//: Lenses
let titleLens = Lens<Article, String>(
  get: { article in article.title },
  set: { article, newTitle in Article(title: newTitle, subtitle: article.subtitle, state: article.state, author: article.author) })

extension Article: AutoLens {}
let titleLens2 = Article.lens(for: \.title)
//: Optionals
let subtitleOptional = Optional<Article, String>(
  set: { article, newSubtitle in  Article(title: article.title, subtitle: .some(newSubtitle), state: article.state, author: article.author) },
  getOrModify: { article in article.subtitle.fold({ Either.left(article) }, Either.right) })

extension Article: AutoOptional {}

let subtitleOptional2 = Article.optional(for: \.subtitle)
//: Prisms
let twitterPrism = Prism<SocialMedia, String>(
  getOrModify: { media in
    guard case let .twitter(handle) = media else { return Either.left(media) }
    return Either.right(handle)
},
  reverseGet: SocialMedia.twitter)

extension SocialMedia: AutoPrism {}

let twitterPrism2 = SocialMedia.prism(for: SocialMedia.twitter, matching: { media in
  guard case let .twitter(handle) = media else { return nil }
  return handle
})
//: Isos
let articleIso = Iso<Article, (String, Option<String>, PublicationState, Author)>(
  get: { article in (article.title, article.subtitle, article.state, article.author) },
  reverseGet: Article.init)
//: Traversals
extension Blog: AutoLens {}

let articlesLens = Blog.lens(for: \.articles)
let articleTraversal = articlesLens + Array<Article>.traversal

extension Blog: AutoTraversal {}
let articleTraversal2 = Blog.traversal(for: \.articles)

//: Folds
let articleFold = articlesLens + [Article].fold

extension Blog: AutoFold {}
let articleFold2 = Blog.fold(for: \.articles)

//: Problem revisited
extension Author: AutoTraversal {}

let articles: Traversal<Blog, Article> = Blog.traversal(for: \.articles)
let author: Lens<Article, Author> = Article.lens(for: \.author)
let social: Traversal<Author, SocialMedia> = Author.traversal(for: \.social)
let twitter: Prism<SocialMedia, String> = SocialMedia.prism(for: SocialMedia.twitter, matching: { media in
  guard case let .twitter(handle) = media else { return nil }
  return handle
})

func addAtToTwitterHandle2(in blog: Blog) -> Blog {
  let optic = (articles + author + social + twitter)
  return optic.modify(blog, { handle in "@\(handle)" })
}

print("------------------")
print("Using optics:")
print(addAtToTwitterHandle2(in: blog))
print("------------------")
