import SwiftUI
import MarkdownUI

struct NewsItemView: View {
  @Environment(Hotline.self) private var model: Hotline
  
  var news: NewsInfo
  let depth: Int
  
  static var dateFormatter: DateFormatter = {
    var dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .long
    dateFormatter.timeStyle = .short
    dateFormatter.timeZone = .gmt
    return dateFormatter
  }()
  
  static var relativeDateFormatter: RelativeDateTimeFormatter = {
    var formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    formatter.dateTimeStyle = .named
    formatter.formattingContext = .listItem
    return formatter
  }()
  
  var body: some View {
    HStack(alignment: .center, spacing: 6) {
      if news.type == .bundle || news.type == .category {
        Button {
          news.expanded.toggle()
        } label: {
          Text(Image(systemName: news.expanded ? "chevron.down" : "chevron.right"))
            .bold()
            .font(.system(size: 10))
            .opacity(0.5)
            .frame(alignment: .center)
        }
        .buttonStyle(.plain)
        .frame(width: 10)
        .padding(.leading, 4)
      }
      else if news.type == .article {
        if news.parentID != nil {
          Image(systemName: "arrowshape.turn.up.left.fill")
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .frame(width: 10)
            .foregroundStyle(.secondary)
        }
      }
      Text(news.name)
        .fontWeight((news.type == .bundle || news.type == .category) ? .bold : .regular)
        .lineLimit(1)
        .truncationMode(.tail)
      if news.type == .article && news.articleUsername != nil {
        Text(news.articleUsername!).foregroundStyle(.secondary).lineLimit(1)
      }
      Spacer()
      if news.type == .bundle || news.type == .category {
        Text("^[\(news.count) \(news.type == .bundle ? "Category" : "Post")](inflect: true)")
        
//        Text("\(news.count) \(news.type == .bundle ? "Categories" : "Posts")")
          .foregroundStyle(.secondary)
          .lineLimit(1)
          .padding([.leading, .trailing], 8)
          .padding([.top, .bottom], 2)
          .background(Capsule(style: .circular).stroke(.secondary.opacity(0.3), lineWidth: 1))
      }
      if news.type == .article && news.articleUsername != nil {
        if let d = news.articleDate {
          Text(NewsItemView.relativeDateFormatter.localizedString(for: d, relativeTo: Date.now)).lineLimit(1).foregroundStyle(.secondary)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .padding(.leading, CGFloat(depth * (12 + 10)))
    .onChange(of: news.expanded) {
      if news.type == .bundle || news.type == .category {
        if news.expanded {
          Task {
            await model.getNewsList(at: news.path)
          }
        }
      }
    }
    
    if news.expanded {
      ForEach(news.children.reversed(), id: \.self) { childNews in
        NewsItemView(news: childNews, depth: self.depth + 1).tag(childNews.id)
      }
    }
  }
}

struct NewsView: View {
  @Environment(Hotline.self) private var model: Hotline
  
  @State private var selection: NewsInfo?
  @State private var articleText: String?
  
  var body: some View {
    NavigationStack {
      VSplitView {
        
        // MARK: News Browser
        List(model.news, id: \.self, selection: $selection) { newsItem in
          NewsItemView(news: newsItem, depth: 0).tag(newsItem.id)
        }

        .frame(maxWidth: .infinity, minHeight: 100, idealHeight: 100)
        .environment(\.defaultMinListRowHeight, 34)
        .listStyle(.inset)
        .alternatingRowBackgrounds(.enabled)
        .task {
          if !model.newsLoaded {
            let _ = await model.getNewsList()
          }
        }
        .contextMenu(forSelectionType: NewsInfo.self) { items in
            // ...
        } primaryAction: { items in
          print("ITEMS?", items)
          guard let clickedNews = items.first else {
            return
          }
          
          self.selection = clickedNews
          if clickedNews.type == .bundle || clickedNews.type == .category {
            clickedNews.expanded.toggle()
          }
        }
        .onChange(of: selection) {
          if
            let article = selection,
            article.type == .article {
            self.articleText = nil
            if
//              let article = self.articleSelection.selectedArticle,
              let articleFlavor = article.articleFlavors?.first,
              let articleID = article.articleID {
              Task {
                if let articleText = await self.model.getNewsArticle(id: articleID, at: article.path, flavor: articleFlavor) {
                  self.articleText = articleText
                }
              }
            }
          }
        }
        .onKeyPress(.rightArrow) {
          if let s = selection, s.type == .bundle || s.type == .category {
            s.expanded = true
            return .handled
          }
          return .ignored
        }
        .onKeyPress(.leftArrow) {
          if let s = selection, s.type == .bundle || s.type == .category {
            s.expanded = false
            return .handled
          }
          return .ignored
        }
        .overlay {
          if !model.newsLoaded {
            VStack {
              ProgressView()
                .controlSize(.large)
            }
            .frame(maxWidth: .infinity)
          }
        }
        
        // MARK: Article Viewer
        ScrollView {
          VStack(alignment: .leading, spacing: 0) {
            if let news = selection {
              if news.type == .article {
                
//                Text(news.name).font(.title)
//                  .textSelection(.enabled)
//                  .padding(.bottom, 8)
                
                if let poster = news.articleUsername, let postDate = news.articleDate {
                  HStack(alignment: .firstTextBaseline) {
                    Text(poster)
                      .foregroundStyle(.secondary)
                      .lineLimit(1)
                      .truncationMode(.tail)
                      .textSelection(.enabled)
                      .padding(.bottom, 16)
                    Spacer()
                    Text("\(NewsItemView.dateFormatter.string(from: postDate))")
                      .foregroundStyle(.secondary)
                      .lineLimit(1)
                      .truncationMode(.tail)
                      .textSelection(.enabled)
                      .padding(.bottom, 16)
                  }
                }
                
                Divider()
                
                if let newsText = self.articleText {
                  Markdown(newsText)
//                  Text(newsText)
                    .textSelection(.enabled)
                    .lineSpacing(4)
                    .padding(.top, 16)
                }
              }
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding()
        }
        .frame(maxWidth: .infinity, minHeight: 200)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color(nsColor: .textBackgroundColor))
    }
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          
        } label: {
          Image(systemName: "square.and.pencil")
        }
      }
      
      ToolbarItem(placement: .primaryAction) {
        Button {
          
        } label: {
          Image(systemName: "arrowshape.turn.up.left")
        }
      }
      
//      if let bannerImage = model.bannerImage {
//        ToolbarItem(placement: .primaryAction) {
////          HStack {
//            bannerImage
//              .resizable()
//              .aspectRatio(contentMode: .fit)
//              .clipped()
//              .frame(minHeight: 60, alignment: .topLeading
//              )
//              .clipped()
//          }
//          .frame(maxWidth: .infinity)
//          .tag(MenuItem(name: "title", image: "", type: .banner))
//          .padding(.bottom, 16)
          
          //           VStack(spacing: 0) {
          //             bannerImage
          //               .resizable()
          //               .aspectRatio(contentMode: .fit)
          //               .frame(maxWidth: .infinity, minHeight: 60, alignment: .topLeading)
          //               .clipped()
          //           }
          //           .frame(maxWidth: .infinity)
//        }
//      }
    }
  }
}

#Preview {
  NewsView()
    .environment(Hotline(trackerClient: HotlineTrackerClient(), client: HotlineClient()))
}
