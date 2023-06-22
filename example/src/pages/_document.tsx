import { Html, Head, Main, NextScript } from 'next/document'
import { Container, Header } from 'nhsuk-react-components'

export default function Document() {
  return (
    <Html lang="en">
      <Head />
      <body>
        <Header transactional>
          <Header.Container>
            <Header.Logo href="/" />
            <Header.ServiceName href="/">Next.js Feature Test App</Header.ServiceName>
          </Header.Container>
        </Header>
        <Container className="nhsuk-u-padding-top-5 nhsuk-u-padding-bottom-5">
          <Main />
        </Container>
        <NextScript />
      </body>
    </Html>
  )
}
