//
//  XMLParserHelper.swift
//  SnipeeIOS
//

import Foundation

class XMLParserHelper: NSObject, XMLParserDelegate {

    private var folders: [SnippetFolder] = []
    private var currentFolder: SnippetFolder?
    private var currentSnippet: Snippet?
    private var currentElement: String = ""
    private var currentValue: String = ""

    func parse(data: Data) -> [SnippetFolder] {
        print("📱 [XMLParser] parse() 開始: \(data.count) bytes")
        folders = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        let success = parser.parse()
        print("📱 [XMLParser] parse() 完了: success=\(success), フォルダ数=\(folders.count)")
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
        } else if elementName == "snippet" {
            currentSnippet = Snippet(
                title: "",
                content: "",
                folder: currentFolder?.name ?? "",
                type: .master,
                order: currentFolder?.snippets.count ?? 0
            )
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue += string
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        let trimmedValue = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if elementName == "folder" {
            if let folder = currentFolder {
                print("📱 [XMLParser] フォルダ追加: \(folder.name) (\(folder.snippets.count) スニペット)")
                folders.append(folder)
            }
            currentFolder = nil
        } else if elementName == "snippet" {
            if let snippet = currentSnippet, currentFolder != nil {
                currentFolder?.snippets.append(snippet)
            }
            currentSnippet = nil
        } else if elementName == "title" {
            if currentSnippet != nil {
                currentSnippet?.title = trimmedValue
            } else if currentFolder != nil {
                currentFolder?.name = trimmedValue
            }
        } else if elementName == "content" {
            currentSnippet?.content = trimmedValue
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("❌ [XMLParser] エラー: \(parseError.localizedDescription)")
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
