import { render, screen } from '@testing-library/react';
import App from './App';

test('renders the home screen', async () => {
  render(<App />);
  expect(await screen.findByText('Quran Quizz')).toBeInTheDocument();
  expect(screen.getByText('Entraînement')).toBeInTheDocument();
});
