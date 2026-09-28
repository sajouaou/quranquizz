describe('Home', () => {
  it('shows the game modes', () => {
    cy.visit('/')
    cy.contains('h1', 'Quran Quizz')
    cy.contains('Entraînement')
    cy.contains('Jouer en ligne')
  })

  it('opens a training game', () => {
    cy.visit('/')
    cy.contains('Entraînement').click()
    cy.contains('Commencer')
  })
})
