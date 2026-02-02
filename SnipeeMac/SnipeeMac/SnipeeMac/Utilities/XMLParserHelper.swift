
//
//  XMLParserHelper.swift
//  SnipeeMac
//

import Foundation

class XMLParserHelper: NSObject, XMLParserDelegate {
    
    private var folders: [SnippetFolder] = []
    private var currentFolder: SnippetFolder?
    private var currentSnippet: Snippet?
    private var currentElement: String = ""
    private var currentValue: String = ""
    
    func parse(data: Data) -> [SnippetFolder] {
        print("🔍 [XMLParserHelper] parse(data:) called, size: \(data.count) bytes")
        folders = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        print("  - Parsed \(folders.count) folders")
        for folder in folders {
            print("    📁 \(folder.name) (id: \(folder.id))")
            for snippet in folder.snippets {
                print("      📝 \(snippet.title) (id: \(snippet.id)) - \(String(snippet.content.prefix(30)))...")
            }
        }
        return folders
    }
    
    func parse(xmlString: String) -> [SnippetFolder] {
        guard let data = xmlString.data(using: .utf8) else { return [] }
        return parse(data: data)
    }
    
    // MARK: - XMLParserDelegate
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        currentValue = ""

        if elementName == "folder" {
            currentFolder = SnippetFolder(name: "", snippets: [], order: folders.count)
            print("  🔍 [XML] Start <folder> order=\(folders.count)")
        } else if elementName == "snippet" {
            currentSnippet = Snippet(title: "", content: "", folder: currentFolder?.name ?? "", type: .master, order: currentFolder?.snippets.count ?? 0)
            print("  🔍 [XML] Start <snippet> in folder '\(currentFolder?.name ?? "nil")' order=\(currentFolder?.snippets.count ?? 0)")
            print("    - New snippet id: \(currentSnippet?.id ?? "nil")")
        }
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let trimmedValue = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if elementName == "folder" {
            if let folder = currentFolder {
                print("  🔍 [XML] End </folder> name='\(folder.name)' with \(folder.snippets.count) snippets")
                folders.append(folder)
            }
            currentFolder = nil
        } else if elementName == "snippet" {
            if let snippet = currentSnippet, currentFolder != nil {
                print("  🔍 [XML] End </snippet> title='\(snippet.title)' id=\(snippet.id)")
                print("    - content (first 50): \(String(snippet.content.prefix(50)))...")
                print("    - folder at append time: '\(currentFolder?.name ?? "nil")'")
                currentFolder?.snippets.append(snippet)
            }
            currentSnippet = nil
        } else if elementName == "title" {
            if currentSnippet != nil {
                print("  🔍 [XML] Set snippet title='\(trimmedValue)'")
                currentSnippet?.title = trimmedValue
            } else if currentFolder != nil {
                print("  🔍 [XML] Set folder name='\(trimmedValue)'")
                currentFolder?.name = trimmedValue
            }
        } else if elementName == "content" {
            print("  🔍 [XML] Set snippet content (first 50): \(String(trimmedValue.prefix(50)))...")
            currentSnippet?.content = trimmedValue
        } else if elementName == "description" {
            currentSnippet?.description = trimmedValue
        }
    }
    
    // MARK: - Export to XML
    
    static func export(folders: [SnippetFolder]) -> String {
        var xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xml += "<snippets>\n"
        
        for folder in folders {
            xml += "  <folder>\n"
            xml += "    <title>\(escapeXML(folder.name))</title>\n"
            
            for snippet in folder.snippets {
                xml += "    <snippet>\n"
                xml += "      <title>\(escapeXML(snippet.title))</title>\n"
                xml += "      <content>\(escapeXML(snippet.content))</content>\n"
                if let description = snippet.description {
                    xml += "      <description>\(escapeXML(description))</description>\n"
                }
                xml += "    </snippet>\n"
            }
            
            xml += "  </folder>\n"
        }
        
        xml += "</snippets>"
        return xml
    }
    
    private static func escapeXML(_ string: String) -> String {
        var result = string
        result = result.replacingOccurrences(of: "&", with: "&amp;")
        result = result.replacingOccurrences(of: "<", with: "&lt;")
        result = result.replacingOccurrences(of: ">", with: "&gt;")
        result = result.replacingOccurrences(of: "\"", with: "&quot;")
        result = result.replacingOccurrences(of: "'", with: "&apos;")
        return result
    }
}
