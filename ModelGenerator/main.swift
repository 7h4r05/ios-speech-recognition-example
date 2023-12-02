//
//  main.swift
//  ModelGEnerator
//
//  Created by Dariusz Zabrzeński on 11/11/2023.
//

import Foundation

import Speech


let data = SFCustomLanguageModelData(locale: Locale(identifier: "en_US"), identifier: "site.modista.speechRecognizer.SpeechRecognition", version: "1.0") {

    SFCustomLanguageModelData.PhraseCountsFromTemplates(classes: [
        "color": ["red", "blue", "green", "yellow"]
    ]) {
        SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template(
            "Set background to <color>",
            count: 10_000
        )
    }
    SFCustomLanguageModelData.PhraseCountsFromTemplates(classes: [
        "element": ["fire", "sea"]
    ]) {
        SFCustomLanguageModelData.TemplatePhraseCountGenerator.Template(
            "I am <element>",
            count: 10_000
        )
    }
    
    SFCustomLanguageModelData.CustomPronunciation(grapheme: "Aw Aw R", phonemes: ["aU aU @r"])
    
    SFCustomLanguageModelData.PhraseCount(phrase: "See the sea", count: 100)
    
}

try await data.export(to: URL(filePath: "<path>/MLData.bin"))


