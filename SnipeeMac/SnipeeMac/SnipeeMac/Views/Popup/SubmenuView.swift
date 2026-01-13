//
//  SubmenuView.swift
//  SnipeeMac
//

import SwiftUI

struct SubmenuView: View {
    let items: [Snippet]
    let theme: ColorTheme
    let onSelect: (Snippet) -> Void
    
    @State private var selectedIndex: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, snippet in
                        Button(action: { onSelect(snippet) }) {
                            HStack {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundColor(theme.secondaryTextColor)
                                    .frame(width: 24)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(snippet.title)
                                        .font(.system(size: 13))
                                        .foregroundColor(theme.textColor)
                                        .lineLimit(1)
                                    
                                    if let description = snippet.description, !description.isEmpty {
                                        Text(description)
                                            .font(.caption)
                                            .foregroundColor(theme.secondaryTextColor)
                                            .lineLimit(1)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(selectedIndex == index ? theme.selectedColor : Color.clear)
                            .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 4)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(width: Constants.UI.submenuWidth)
        .frame(maxHeight: Constants.UI.submenuMaxHeight)
        .background(theme.backgroundColor)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 2, y: 2)
    }
}
