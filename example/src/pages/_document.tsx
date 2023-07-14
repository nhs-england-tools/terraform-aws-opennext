import { Html, Head, Main, NextScript } from 'next/document'
import Link from 'next/link'
import { Container, Footer, Header } from 'nhsuk-react-components'

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
        <Footer>
          <Footer.List>
            <Footer.ListItem><Link href="/">Home</Link></Footer.ListItem>
          </Footer.List>
          <Footer.Copyright>
            &copy; Crown Copyright {new Date().getFullYear()}
          </Footer.Copyright>
        </Footer>
        <NextScript />
      </body>
    </Html>
  )
}
