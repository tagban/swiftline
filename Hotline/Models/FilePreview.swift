import SwiftUI

//struct FilePreview: Identifiable, Hashable {
//  let id: UUID
//  
//  let path: [String]
//  let name: String
//  
//  let type: String
//  let creator: String
//  let fileSize: UInt
//  
//  let isFolder: Bool
//  let isUnavailable: Bool
//  var expanded: Bool = false
//  var children: [FileInfo]? = nil
//  
//  init(hotlineFile: HotlineFile) {
//    self.id = UUID()
//    self.path = hotlineFile.path
//    self.name = hotlineFile.name
//    self.type = hotlineFile.type
//    self.creator = hotlineFile.creator
//    self.fileSize = UInt(hotlineFile.fileSize)
//    self.isFolder = hotlineFile.isFolder
//    self.isUnavailable = (!self.isFolder && (self.fileSize == 0))
//    
//    print(self.name, self.type, self.creator, self.isUnavailable)
//    if self.isFolder {
//      self.children = []
//    }
//  }
//  
//  static func == (lhs: FileInfo, rhs: FileInfo) -> Bool {
//    return lhs.id == rhs.id
//  }
//  
//  func hash(into hasher: inout Hasher) {
//    hasher.combine(self.id)
//  }
//}
