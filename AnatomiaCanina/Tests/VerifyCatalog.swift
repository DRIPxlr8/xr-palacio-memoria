import Foundation

@main
enum VerifyCatalog {
    static func main() throws {
        verifyPlacement()
        verifyStationDimensions()
        verifyQuiz()
        verifyQuizColors()
        verifyQuestionsFromConfirmedStations()
        try verifyProgressFormat()
        print("Verificados los colores por pieza, las respuestas, la colocación, la altura, el tamaño y la persistencia.")
    }

    private static func verifyPlacement() {
        func point(_ x: Float, _ y: Float = 0, _ z: Float = 0) -> StationPlacement {
            StationPlacement(position: [x, y, z], facing: 0.5)
        }

        var layout = PalaceLayout()
        precondition(layout.preview(.shoulder, at: point(0)))
        precondition(layout.visiblePlacement(for: .shoulder) == point(0))
        precondition(layout.stations.isEmpty)
        layout.cancelPlacement()
        layout.confirmPlacement()
        precondition(layout.visiblePlacement(for: .shoulder) == nil)
        precondition(layout.stations.isEmpty)

        precondition(layout.preview(.shoulder, at: point(0)))
        layout.confirmPlacement()
        precondition(!layout.preview(.elbow, at: point(0.10)))
        precondition(layout.draft == nil)
        precondition(layout.preview(.elbow, at: point(0.65)))
        layout.confirmPlacement()
        precondition(layout.preview(.carpus, at: point(0.65, 0.60)))
        layout.confirmPlacement()
        precondition(layout.stations.count == 3)

        let before = layout.stations
        precondition(layout.preview(.shoulder, at: point(-0.52)))
        precondition(!layout.preview(.shoulder, at: point(0.65)))
        precondition(layout.visiblePlacement(for: .shoulder) == point(-0.52))
        precondition(layout.stations == before)
        layout.cancelPlacement()
        precondition(layout.visiblePlacement(for: .shoulder) == before[.shoulder])

        precondition(layout.preview(.shoulder, at: point(-0.52)))
        layout.confirmPlacement()
        precondition(layout.stations[.shoulder] == point(-0.52))
        precondition(layout.stations[.elbow] == before[.elbow])
        precondition(layout.stations[.carpus] == before[.carpus])
        layout.remove(.shoulder)
        precondition(layout.visiblePlacement(for: .shoulder) == nil)
        precondition(layout.stations.count == 2)
    }

    private static func verifyStationDimensions() {
        let origin = StationPlacement(position: [0, 0, 0], facing: 0)
        let other = StationPlacement(position: [1, 0, 0], facing: 0.5)
        let moved = StationPlacement(position: [0, 0.6, 1], facing: 0.8)
        var layout = PalaceLayout()

        precondition(layout.preview(.shoulder, at: origin))
        layout.adjustDraft(elevation: 1.05, scale: 1.4)
        precondition(layout.preview(.shoulder, at: moved))
        precondition(layout.visiblePlacement(for: .shoulder)?.dimensions == StationDimensions(elevation: 1.05, scale: 1.4))
        precondition(layout.stations.isEmpty)
        layout.confirmPlacement()
        precondition(layout.stations[.shoulder]?.position == moved.position)
        precondition(layout.stations[.shoulder]?.facing == moved.facing)
        let first = layout.stations[.shoulder]

        precondition(layout.preview(.elbow, at: other))
        layout.confirmPlacement()
        layout.beginEditing(.shoulder)
        precondition(layout.draft?.placement == first)
        layout.adjustDraft(elevation: 9, scale: 0.01)
        precondition(layout.visiblePlacement(for: .shoulder)?.dimensions == StationDimensions(elevation: 1.8, scale: 0.5))
        precondition(layout.stations[.shoulder] == first)
        layout.cancelPlacement()
        precondition(layout.visiblePlacement(for: .shoulder) == first)
        precondition(layout.stations[.elbow] == other)

        layout.beginEditing(.shoulder)
        layout.adjustDraft(elevation: 0.9)
        layout.resizeStation(.shoulder, to: 1.8)
        precondition(layout.stations[.shoulder] == first)
        layout.confirmPlacement()
        precondition(layout.stations[.shoulder]?.position == first?.position)
        precondition(layout.stations[.shoulder]?.dimensions == StationDimensions(elevation: 0.9, scale: 1.8))
        layout.resizeStation(.shoulder, to: 0.75)
        precondition(layout.stations[.shoulder]?.dimensions == StationDimensions(elevation: 0.9, scale: 0.75))
        precondition(layout.stations[.elbow] == other)
    }

    private static func verifyQuiz() {
        let questions = Region.allCases.flatMap { region in
            region.targets.map { QuizQuestion(region: region, target: $0) }
        }
        precondition(questions.count == 12)
        precondition(Set(questions.map(\.target.id)).count == questions.count)
        precondition(QuizRound(regions: [.shoulder, .carpus]).questions.count == 8)
        precondition(QuizRound(regions: [.elbow]).questions.allSatisfy { $0.region == .elbow })

        var round = QuizRound(questions: questions)
        precondition(!round.select(part: "no-structure", region: .shoulder))
        round.confirmAnswer()
        precondition(round.answers.isEmpty)
        round.next()
        precondition(round.index == 0)
        for (index, question) in questions.enumerated() {
            precondition(round.current == question)
            let correctPart = question.target.parts.sorted().first!
            let alternative = question.target.level == .basic ? "radius" : "radial_head"
            precondition(round.select(part: alternative, region: .elbow))
            precondition(round.answers.count == index)
            if index > 0 { precondition(round.select(part: correctPart, region: question.region)) }
            precondition(!round.select(part: "no-structure", region: .shoulder))
            round.confirmAnswer()
            precondition(round.feedback?.correct == (index != 0))
            precondition(round.selection?.region == (index == 0 ? .elbow : question.region))
            precondition(!round.select(part: correctPart, region: question.region))
            round.confirmAnswer()
            precondition(round.answers.count == index + 1)
            round.next()
            precondition(round.selection == nil)
        }

        precondition(round.current == nil)
        precondition(round.answersByRegion[.shoulder]?.filter(\.correct).count == 3)
        precondition(round.answersByRegion[.elbow]?.filter(\.correct).count == 4)
        precondition(round.answersByRegion[.carpus]?.filter(\.correct).count == 4)
    }

    private static func verifyQuizColors() {
        let expectedCounts: [Region: Int] = [.shoulder: 4, .elbow: 5, .carpus: 6]
        for region in Region.allCases {
            let colors = region.quizColors
            precondition(Set(colors.keys) == Set(region.modelParts.map(\.id)))
            precondition(Set(colors.values).count == expectedCounts[region])
            for part in region.modelParts {
                var quiz = QuizRound(regions: [region])
                precondition(quiz.select(part: part.id, region: region))
                precondition(quiz.selection?.part == part)
                let correct = quiz.current?.target.parts.contains(part.id)
                quiz.confirmAnswer()
                precondition(quiz.feedback?.correct == correct)
            }
        }

        let largerPalette = QuizZoneColor.palette(count: 11)
        precondition(Set(largerPalette.map(\.hue)).count == 11)

        let arm = Region.elbow.targets
        let radialHead = QuizQuestion(region: .elbow, target: arm.first { $0.id == "radial_head" }!)
        var detail = QuizRound(questions: [radialHead])
        precondition(detail.select(part: "radius", region: .elbow))
        detail.confirmAnswer()
        precondition(detail.feedback?.correct == false)

        let radius = QuizQuestion(region: .elbow, target: arm.first { $0.id == "radius" }!)
        var basic = QuizRound(questions: [radius])
        precondition(basic.select(part: "radial_head", region: .elbow))
        basic.confirmAnswer()
        precondition(basic.feedback?.correct == true)
    }

    private static func verifyQuestionsFromConfirmedStations() {
        let origin = StationPlacement(position: [0, 0, 0], facing: 0)
        let nextPoint = StationPlacement(position: [1, 0, 0], facing: 0)
        var layout = PalaceLayout()
        precondition(layout.preview(.shoulder, at: origin))
        layout.confirmPlacement()
        precondition(layout.preview(.elbow, at: nextPoint))

        var quiz = QuizRound(regions: Array(layout.stations.keys))
        precondition(quiz.questions.count == 4)
        precondition(quiz.questions.allSatisfy { $0.region == .shoulder })
        precondition(Set(quiz.questions.map(\.instruction)) == [
            "Toca la escápula.", "Toca el húmero.",
            "Toca la cavidad glenoidea de la escápula.", "Toca la cabeza del húmero.",
        ])
        precondition(!quiz.select(part: "radius", region: .elbow))
        precondition(quiz.selection == nil)
        guard let current = quiz.current,
              let other = quiz.questions.first(where: {
                  $0.target.level == current.target.level && $0.target.id != current.target.id
              }),
              let otherPart = other.target.parts.first else {
            preconditionFailure("Cada nivel debe tener otra estructura seleccionable")
        }
        precondition(quiz.select(part: otherPart, region: .shoulder))
        quiz.confirmAnswer()
        precondition(quiz.feedback?.correct == false)
        precondition(quiz.selection?.region == other.region && quiz.selection?.part.id == otherPart)

        layout.confirmPlacement()
        layout.remove(.shoulder)
        let elbow = QuizRound(regions: Array(layout.stations.keys))
        precondition(elbow.questions.count == 4 && elbow.questions.allSatisfy { $0.region == .elbow })
        precondition(elbow.questions.contains { $0.instruction == "Toca el olécranon de la ulna." })
    }

    private static func verifyProgressFormat() throws {
        let progress = RegionProgress(explored: ["scapula"], latestQuiz: [Answer(targetID: "scapula", correct: true)])
        let saved = try JSONEncoder().encode([Region.shoulder: progress])
        let restored = try JSONDecoder().decode([Region: RegionProgress].self, from: saved)
        precondition(restored[.shoulder]?.explored == progress.explored)
        precondition(restored[.shoulder]?.latestQuiz == progress.latestQuiz)
    }
}
