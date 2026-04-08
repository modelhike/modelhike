import Foundation
import ModelHike

enum DiagnosticExtractor {
    static func extract(from session: DebugSession) -> [Diagnostic] {
        var diagnostics: [Diagnostic] = []

        for envelope in session.events {
            switch envelope.event {
            case .diagnostic(let severity, let code, let message, let source, let suggestions):
                diagnostics.append(
                    Diagnostic(
                        severity: map(severity),
                        code: code,
                        message: message,
                        source: map(source),
                        suggestions: suggestions.map(map)
                    )
                )
            case .error(_, let code, let message, let source, _):
                diagnostics.append(
                    Diagnostic(
                        severity: .error,
                        code: code,
                        message: message,
                        source: map(source)
                    )
                )
            default:
                continue
            }
        }

        for error in session.errors {
            diagnostics.append(
                Diagnostic(
                    severity: .error,
                    message: error.message,
                    source: map(error.source)
                )
            )
        }

        return deduplicate(diagnostics)
    }

    static func singleError(_ error: Error) -> [Diagnostic] {
        [
            Diagnostic(
                severity: .error,
                message: String(describing: error)
            )
        ]
    }

    private static func map(_ severity: ModelHike.DiagnosticSeverity) -> DiagnosticSeverity {
        switch severity {
        case .error: .error
        case .warning: .warning
        case .info: .info
        case .hint: .hint
        }
    }

    private static func map(_ suggestion: ModelHike.DiagnosticSuggestion) -> Suggestion {
        let kind: SuggestionKind = switch suggestion.kind {
        case .didYouMean: .didYouMean
        case .availableOptions: .availableOptions
        case .note: .note
        }

        return Suggestion(
            kind: kind,
            message: suggestion.message,
            replacement: suggestion.replacement,
            options: suggestion.options
        )
    }

    private static func map(_ source: ModelHike.SourceLocation) -> SourceRef {
        SourceRef(
            fileIdentifier: source.fileIdentifier,
            lineNo: source.lineNo,
            lineContent: source.lineContent,
            level: source.level
        )
    }

    private static func deduplicate(_ diagnostics: [Diagnostic]) -> [Diagnostic] {
        var seen = Set<String>()
        var result: [Diagnostic] = []

        for diagnostic in diagnostics {
            let source = diagnostic.source
            let key = [
                diagnostic.severity.rawValue,
                diagnostic.code ?? "",
                diagnostic.message,
                source?.fileIdentifier ?? "",
                String(source?.lineNo ?? 0),
            ].joined(separator: "|")

            if seen.insert(key).inserted {
                result.append(diagnostic)
            }
        }

        return result.sorted {
            if $0.severity.rank != $1.severity.rank {
                return $0.severity.rank < $1.severity.rank
            }
            if ($0.code ?? "") != ($1.code ?? "") {
                return ($0.code ?? "") < ($1.code ?? "")
            }
            return $0.message < $1.message
        }
    }
}
